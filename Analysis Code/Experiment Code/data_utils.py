# This script has functions for managing a database of LLM responses for analysis.
# The purpose of the database is to allow for slowly accumulating data over time
# instead of being forced to do it all at once.

# It also contains functions for parsing session logs and adding them to the database.
# Real-world log files from the game are supported,
# as well as those from the synthetic data generation pipeline.

import sqlite3
import json
import os
import hashlib
import pandas as pd
from datetime import datetime



def create_connection(db_file):
    # Just abstracts away connection to avoid an sqlite3 import in the main notebook
    conn = sqlite3.connect(db_file)
    print(f"Connected to database at {db_file}")
    return conn



def init_database(conn):
    """
    Defines the table schema and creates it.
    
    This schema has changed a few times, previously embedding just about everything in JSON.
    It now has a more flattened format with separate columns for each outcome.
    """

    sql = """
    CREATE TABLE IF NOT EXISTS responses (
        row_id INTEGER PRIMARY KEY AUTOINCREMENT,
        problem_hash TEXT NOT NULL,
        session_name TEXT NOT NULL,
        task_key TEXT NOT NULL,
        input TEXT,
        context TEXT,
        procedural INTEGER,
        procedural_code TEXT,
        model_response TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        judge_rationales_json TEXT,
        judged_at DATETIME,
        ingested_at DATETIME NOT NULL,
        
        model_name TEXT,
        shot_strategy TEXT,
        planning INTEGER,
        
        score_creative_alignment INTEGER,
        score_instructional_precision INTEGER,
        score_emergence INTEGER,
        score_structural_coherence INTEGER,
        score_programmatic_validation TEXT,
        score_tree_edit_distance INTEGER,
        score_jaccard_similarity REAL,
        
        param_nesting_complexity INTEGER,
        param_component_complexity INTEGER,
        param_max_sentences_for_desc INTEGER
    );
    """

    cursor = conn.cursor()

    # Remove previous table if it exists, and create new one
    cursor.execute("DROP TABLE IF EXISTS responses")
    cursor.execute(sql)
    conn.commit()
    print("Database ready!")



def clear_all_responses(conn):
    # Deletes all records and resets autoincrement

    sql_delete = "DELETE FROM responses;"
    sql_reset_inc = "DELETE FROM sqlite_sequence WHERE name='responses';"

    # Execute everything
    cursor = conn.cursor()
    cursor.execute(sql_delete)
    cursor.execute(sql_reset_inc)
    conn.commit()
    print("Table has been cleared")



def get_record_count(conn):
    # Gets the total number of records in the table

    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM responses;")
    count = cursor.fetchone()[0]
    print(f"Total records in database: {count}")
    return count



def get_record_status(conn):
    #Gets the count of records for each judging status

    # Groupby by status to get counts for each
    sql = "SELECT status, COUNT(*) FROM responses GROUP BY status;"

    cursor = conn.cursor()
    cursor.execute(sql)
    rows = cursor.fetchall()
    print("Database status:")

    if not rows:
        print("No records found!")
    for row in rows:
        print(f"Status: {row[0]}, Count: {row[1]}")

    return rows



def db_tasks_to_json_file(conn, output_file="synthetic_tasks/spellScripting_tasks.json"):
    """
    Finds the set of unique inputs from the database, and creates a task file.
    Written for adding Gemma 3 to analysis and needing to recover the original inputs.
    """

    cursor = conn.cursor()

    # Find all unique problem_hash values
    cursor.execute("SELECT DISTINCT problem_hash FROM responses")
    unique_hashes = [row[0] for row in cursor.fetchall()]

    print(f"Found {len(unique_hashes)} unique problem hashes.")

    final_tasks = []
    for problem_hash in unique_hashes:
        # For each hash, get the corresponding task data.
        # We only need one record per unique hash
        cursor.execute("SELECT input, context, procedural, param_max_sentences_for_desc FROM responses WHERE problem_hash = ? LIMIT 1", (problem_hash,))
        record = cursor.fetchone()

        if record:
            input_desc, context_json, procedural_val, max_sentences = record
                
            # The context is stored as a JSON string
            context_list = json.loads(context_json)

            # Wrap it all up to save
            task_data = {
                "input": input_desc,
                "context": context_list,
                "metadata": {
                    "procedural": procedural_val if procedural_val is not None else 0,
                    "max_sentences_for_desc": max_sentences if max_sentences is not None else 2
                }
            }
            final_tasks.append(task_data)

    # Write the final list of tasks to the given output file
    if final_tasks:
        with open(output_file, 'w') as f:
            json.dump(final_tasks, f, indent=2)
        print(f"\nExtracted and saved {len(final_tasks)} tasks to {output_file}")



def parse_group_name(group_name):
    """
    Parses a group name string to extract the model name, shot strategy,
    and planning flag. Files are of the form 'gpt-4.1-zeroshot-planning'
    """

    # Defaults if it were not named this way
    shot_strategy = "unknown"
    planning = 0
    model_name = group_name

    # Shot strategy keywords to support
    strategy_keywords = ["zeroshot", "oneshot", "fewshot", "test_group"]
    
    # Try to find a shot strategy keyword in the group name
    split_index = -1
    for keyword in strategy_keywords:
        index = group_name.find(keyword)
        # If found one, break here and continue
        if index != -1:
            shot_strategy = keyword
            split_index = index
            break
    
    # If a keyword was found, split the group name on it
    if split_index != -1:
        model_name = group_name[:split_index].strip('-')
        strategy_part = group_name[split_index:]
        
        # Check for a planning flag after the shot strategy
        if "planning" in strategy_part:
            planning = 1
    
    # Return a struct with the info
    return {
        "model_name": model_name,
        "shot_strategy": shot_strategy,
        "planning": planning
    }



def parse_log(file_path):
    """
    Parses a log file and returns a list of dictionaries
    for each individual task found inside.
    """

    # Read the entire file contents
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    parsed_sections = []

    # This section header originally comes from the game:
    # see format_log_entry() in nl_to_dsl.py for how they're created
    sections = content.strip().split('[end]')

    # For every section...
    for section_text in sections:

        section_text = section_text.strip()
        if not section_text:
            continue

        # The first line is the header
        lines = section_text.split('\n', 1)
        main_content = lines[1]
        # Remove the square brackets
        header = lines[0].strip()[1:-1]

        # Dict for this section
        section_data = {'task_key': header}
        keys_to_find = ['input::', 'context::', 'metadata::', 'response::']
        
        # Find the starting position of all keys that exist in this section
        # Metadata is an optional key, so some extra work is required
        found_keys = []
        for key in keys_to_find:
            position = main_content.find(key)
            if position != -1:
                found_keys.append({'key': key, 'pos': position})
        
        # Sort the keys by the order they appear (probably uncecessary, but just being safe)
        found_keys.sort(key=lambda x: x['pos'])
        
        # For each key, extract its value
        for i, current_key_info in enumerate(found_keys):
            key_name = current_key_info['key'].removesuffix('::')
            start_pos = current_key_info['pos'] + len(current_key_info['key'])
            
            # The value ends where the next key begins, or at the end of the content
            if i + 1 < len(found_keys):
                end_pos = found_keys[i + 1]['pos']
            else:
                end_pos = len(main_content)
            
            # Add every key's value to the dict
            value = main_content[start_pos:end_pos].strip()
            section_data[key_name] = value

        # Add the section to the output
        parsed_sections.append(section_data)

    return parsed_sections



def insert_response(conn, response_data):
    # Inserts a single response into the database

    columns = [
        'problem_hash', 'session_name', 'task_key', 'input', 'context', 'procedural',
        'procedural_code', 'model_response', 'ingested_at', 'model_name',
        'shot_strategy', 'planning', 'param_nesting_complexity',
        'param_component_complexity', 'param_max_sentences_for_desc'
    ]

    # Create a tuple from the input dict
    record_tuple = tuple(response_data.get(col) for col in columns)

    # Insert into all columns
    sql = f"""
    INSERT OR IGNORE INTO responses ({', '.join(columns)}) 
    VALUES ({', '.join(['?'] * len(columns))});
    """

    cursor = conn.cursor()
    cursor.execute(sql, record_tuple)
    return cursor.lastrowid if cursor.rowcount > 0 else None



def ingest_log_files(db_file, master_folder):
    # Walks the data folder, parses all .txt files, and ingests them into the database

    conn = create_connection(db_file)

    newly_inserted_count = 0
    ignored_count = 0

    # This is a bit ugly, but derives group identifiers from a folder structure
    # It allows for taking in files directly from the game as necessary
    # Structure is master_folder/group_name/session_name.txt
    for group_name in os.listdir(master_folder):
        group_path = os.path.join(master_folder, group_name)

        if os.path.isdir(group_path):
            # Parse the directory name (should be a group identifier)
            parsed_group_info = parse_group_name(group_name)
            for session_name in os.listdir(group_path):

                if session_name.endswith(".txt"):
                    file_path = os.path.join(group_path, session_name)

                    # Parse the file into a list of dicts
                    parsed_data = parse_log(file_path)

                    # Process each task found in the file
                    for task_data in parsed_data:
                        input_val = task_data['input']
                        context_val = task_data['context']

                        # Hash the input+context pair for a unique identifier of problem input
                        id_string = str(input_val) + str(context_val)
                        problem_hash = hashlib.sha256(id_string.encode('utf-8')).hexdigest()

                        # These keys match the database table
                        record_to_insert = {
                            "problem_hash": problem_hash,
                            "session_name": session_name.replace('.txt', ''),
                            "task_key": task_data['task_key'],
                            "input": input_val,
                            "context": context_val,
                            "model_response": task_data['response'],
                            "ingested_at": datetime.now().isoformat(),
                            "model_name": parsed_group_info['model_name'],
                            "shot_strategy": parsed_group_info['shot_strategy'],
                            "planning": parsed_group_info['planning']
                        }
                        
                        # The metadata key is optional, designed for Experiment 2
                        # It holds procedural generation data about a given input
                        if 'metadata' in task_data:
                            metadata = json.loads(task_data['metadata'])
                            procedural_spell = metadata.pop('procedural_spell', None)
                            if procedural_spell:
                                record_to_insert['procedural_code'] = json.dumps(procedural_spell)

                            # Optional metadata keys
                            record_to_insert['procedural'] = metadata.get('procedural')
                            record_to_insert['param_nesting_complexity'] = metadata.get('nesting_complexity')
                            record_to_insert['param_component_complexity'] = metadata.get('component_complexity')
                            record_to_insert['param_max_sentences_for_desc'] = metadata.get('max_sentences_for_desc')
                        
                        # Insert the task into the database
                        inserted_id = insert_response(conn, record_to_insert)
                        if inserted_id:
                            newly_inserted_count += 1
                        else:
                            ignored_count += 1
    
    conn.commit()
    conn.close()
    
    print(f"{newly_inserted_count} new records inserted, {ignored_count} records ignored as duplicates.")



def extract_timestamp_from_key(key_string):
    # Helper function to pull the timestamp out of a task header
    # Used by extract_task_intervals()
    try:
        timestamp_str = '-'.join(key_string.split('-')[-6:])
        return pd.to_datetime(timestamp_str, format='%Y-%m-%d-%H-%M-%S')
    except (IndexError, ValueError):
        return pd.NaT
    


def extract_task_intervals(db_file="judgements.db"):
    """
    Connects to the database and extracts the individual time intervals
    between each sequential task, returning a DataFrame.
    This function was written to infer latency after it wasn't recorded directly.
    """

    conn = create_connection(db_file)

    # Grab everything into a dataframe
    df = pd.read_sql_query("SELECT * FROM responses", conn)
    print(f"Successfully loaded {len(df)} records.")

    # The first 180 records didn't use the "current model" alias like they should have; needs to be fixed
    df['model_name'] = df['model_name'].replace(
        'gemini-2.5-flash-preview-05-20', 'gemini-2.5-flash'
    )

    df['timestamp'] = df['task_key'].apply(extract_timestamp_from_key)

    # Drop missing values, and sort all timestamps
    df.dropna(subset=['timestamp'], inplace=True)
    df.sort_values(by=['session_name', 'timestamp'], inplace=True)
        
    # Calculate time difference between consecutive tasks, within each session
    df['time'] = df.groupby('session_name')['timestamp'].diff().dt.total_seconds()
        
    # Keep only what's strictly necessary for the latency analysis
    output_columns = ['session_name', 'model_name', 'shot_strategy', 'planning', 'time']
    output_df = df[output_columns].copy()

    # The first task in each session will have a NaN time
    output_df.dropna(subset=['time_diff_seconds'], inplace=True)
    
    conn.close()
    return output_df