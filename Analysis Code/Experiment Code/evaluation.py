# This script handles the evaluation of model outputs,
# including syntax validation, similarity measures, and the LLM judge

import os
import json
import time
import sqlite3
from datetime import datetime
from apted import APTED, Config
from apted.helpers import Tree

from data_utils import create_connection
from model_hooks import setup_anthropic, setup_gemini, setup_openai, prompt_anthropic_model, prompt_gemini_model, prompt_openai_model



# Similarity measures



# Class for APTED
class Cost(Config):
    """
    Defines the cost of edit operations for the APTED algorithm.
    Using a simple model where all operations have a cost of 1,
    Since I can't justify any other cost function
    """

    def rename(self, node1, node2):
        return 1 if node1.name != node2.name else 0
    
    def insert(self, node):
        return 1
        
    def delete(self, node):
        return 1



def _sort_spell_components(data):
    """
    Recursively sorts component lists in a spell script by componentType
    to create a canonical ordering for AST comparison.
    """

    if isinstance(data, dict):

        if 'components' in data and isinstance(data['components'], list):
            data['components'].sort(key=lambda x: x.get('componentType', ''))
            for item in data['components']:
                _sort_spell_components(item)

        if 'payload_components' in data and isinstance(data['payload_components'], list):
            data['payload_components'].sort(key=lambda x: x.get('componentType', ''))
            for item in data['payload_components']:
                _sort_spell_components(item)
    return data



def _build_apted_tree(spell_dict):
    # Recursively builds a tree structure compatible with the APTED library

    node_name = spell_dict.get('componentType', 'spell_root')
    children = []

    if 'payload_components' in spell_dict and spell_dict.get('payload_components'):
        for component in spell_dict['payload_components']:
            children.append(_build_apted_tree(component))

    elif 'components' in spell_dict and spell_dict.get('components'):
        for component in spell_dict['components']:
            children.append(_build_apted_tree(component))

    return Tree(node_name, *children)



def _flatten_components(data):
    """
    Recursively finds all component types in a JSON DSL script and returns them as a set.
    Used for calculating Jaccard Similarity as the IoU of component names between two scripts.
    """

    components_set = set()

    if isinstance(data, dict):
        if 'componentType' in data:
            component_type = data.get('componentType')

            if component_type == 'element':
                element_value = data.get('element')
                if element_value: components_set.add(element_value)
            else:
                components_set.add(component_type)

        for value in data.values():
            components_set.update(_flatten_components(value))

    elif isinstance(data, list):
        for item in data:
            components_set.update(_flatten_components(item))

    return components_set



def calculate_spell_similarity(source_json, model_json):
    # Calculates the structural similarity between two spell scripts

    # It used to break here for invalid JSON, handling this explicitly now
    try:
        source_data = json.loads(source_json)
        model_data = json.loads(model_json)
    except json.JSONDecodeError:
        print("Could not calculate similarity as model response was not valid JSON.")
        return {"tree_edit_distance": -1, "jaccard_similarity": -1}

    # Tree edit distance
    # Build trees for each script
    sorted_source = _sort_spell_components(source_data)
    sorted_model = _sort_spell_components(model_data)
    source_tree = _build_apted_tree(sorted_source)
    model_tree = _build_apted_tree(sorted_model)

    # Use the APTED algorithm to compare them
    apted = APTED(source_tree, model_tree, Cost())
    tree_dist = apted.compute_edit_distance()

    # Jaccard Similarity
    # Flatten each script
    source_comps = _flatten_components(sorted_source)
    model_comps = _flatten_components(sorted_model)

    # Take intersection over union
    intersection = len(source_comps.intersection(model_comps))
    union = len(source_comps.union(model_comps))
    jaccard = intersection / union if union != 0 else 0

    return {"tree_edit_distance": tree_dist, "jaccard_similarity": round(jaccard, 4)}




# Syntax validation functions



def validate_spell_script(response_text):
    """
    Validates if the LLM response for the spell scripting task is syntactically correct.

    This function checks for:
     - Valid JSON format
     - Presence of root keys 'friendlyName' and 'components'
     - That each component in the components list is an object with a componentType key
     - The structural integrity of key components
     - Recursively validates the structure of any payload components within triggers

    """

    # Validate JSON
    try:
        data = json.loads(response_text)
    except json.JSONDecodeError:
        print("Validation Error: Response is not valid JSON.")
        return False

    # Check top level structure
    if not isinstance(data, dict):
        print("Validation Error: Top level structure must be a JSON object.")
        return False
    
    if not isinstance(data.get('friendlyName'), str) or not isinstance(data.get('components'), list):
        print("Validation Error: Must have friendlyName and components at the root.")
        return False

    # Start recursion on the main components list
    return _validate_components_list(data['components'])



def _validate_components_list(components):
    # A helper function to recursively validate a list of spell components
    
    # A set of known trigger types that must contain a payload
    trigger_types = {"timerTrigger", "buttonTrigger", "impactTrigger", "deathTrigger"}

    if not isinstance(components, list):
        print(f"Validation Error: Expected a list of components, but got {type(components)}.")
        return False

    for component in components:
        if not isinstance(component, dict) or 'componentType' not in component:
            print(f"Validation Error: Found an item in a components list that is not an object with a componentType. Item: {component}")
            return False

        comp_type = component['componentType']

        # Check that colors are rgb triplets
        if comp_type == 'color' and (not isinstance(component.get('rgb'), list) or len(component['rgb']) != 3):
            print(f"Validation Error: color component has an invalid rgb property.")
            return False

        # Recursively evaluate payloads in trigger components
        if comp_type in trigger_types:
            payload = component.get('payload_components')
            if not isinstance(payload, list):
                print(f"Validation Error: Trigger {comp_type} is missing a payload components list.")
                return False
            
            # Recursive call
            if not _validate_components_list(payload):
                return False # Propagate failure from the recursive call

    # If the loop completes without returning, all components in this list are valid
    return True



def validate_ca_script(response_text):
    """
    Validates if the LLM response for the cellular automata task is syntactically correct.

    This function checks for:
     - A valid JSON object
     - Presence of root keys 'name', 'color_hex', and 'behavior'
     - Correct format for name and color_hex
     - The behavior object must contain an actions list
     - Recursively validates that all nodes in actions lists have a type key
       and that nodes that should contain other actions do

    """

    # Check for valid JSON
    try:
        data = json.loads(response_text)
    except json.JSONDecodeError:
        print("Validation Error: Extracted content is not valid JSON.")
        return False

    # Validate the root structure and formats
    if not isinstance(data, dict):
        return False
        
    name = data.get('name')
    color = data.get('color_hex')
    behavior = data.get('behavior')

    if not (isinstance(name, str) and name.islower() and 0 < len(name) <= 15):
        print(f"Validation Error: name is invalid. Got: {name}")
        return False

    if (not isinstance(color, str)) or (len(color) != 7) or (not color.startswith('#')):
        print(f"Validation Error: color_hex is invalid. Got: {color}")
        return False

    if not (isinstance(behavior, dict) and isinstance(behavior.get('actions'), list)):
        print("Validation Error: behavior must be an object with an actions list.")
        return False

    # Start recursive validation on the actions list
    return _validate_actions_list(behavior['actions'])



def _validate_actions_list(actions):
    # A helper function to recursively validate a list of CA nodes
    
    # Node types that can contain a nested actions or else_actions list
    recursive_types = {
        "in_rand_rotation", "in_rand_mirror", "in_rand_flip",
        "if_neighbor_is", "if_neighbor_is_not", "if_alpha",
        "if_neighbor_count", "if_chance", "do_swap"
    }

    if not isinstance(actions, list):
        return False

    for node in actions:
        if not isinstance(node, dict) or not isinstance(node.get('type'), str):
            print(f"Validation Error: Item in an actions list without a valid type. Item: {node}")
            return False

        # If a node is a recursive type, check its nested actions
        if node['type'] in recursive_types:

            if 'actions' in node and not _validate_actions_list(node['actions']):
                return False
            
            # Special case for if-else
            if 'else_actions' in node and not _validate_actions_list(node['else_actions']):
                return False
    
    return True




# LLM judging functions



def build_judge_prompt(rules_file, rubric_file, schema_file, task_input, task_context, task_response, validation_status):
    # Builds a complete prompt for the LLM judge from modular components
    
    try:
        with open(rules_file, 'r') as f: rules = f.read()
        with open(rubric_file, 'r') as f: rubric = f.read()
        with open(schema_file, 'r') as f: schema = f.read()
    except FileNotFoundError as e:
        return f"Could not find a prompt component file: {e}"
    
    return f"""
    You are an expert evaluator. Your task is to act as a judge and assess the quality of a response based on the provided context and input. Your output must be a single, valid JSON object and nothing else.
    TASK RULES
    {rules}
    EVALUATION RUBRIC
    {rubric}
    OUTPUT SCHEMA
    {schema}

    ALGORITHMIC PRE-CHECK
    A programmatic check was run on the response to validate its basic structure and syntax.
    Syntactic validation status: {validation_status}
    (You should factor this pre-check into your final evaluation, especially for correctness scores.)

    TASK FOR EVALUATION
    Input:
    {task_input}
    Context:
    {task_context}
    Response to evaluate:
    {task_response}
    YOUR EVALUATION (JSON ONLY)
    """.strip()



def update_judged_record(conn, row_id, scores_dict, rationales_json):
    # Updates a record in the database with the judging results

    score_column_map = {
        'creative_alignment': 'score_creative_alignment',
        'instructional_precision': 'score_instructional_precision',
        'emergence': 'score_emergence',
        'structural_coherence': 'score_structural_coherence',
        'programmatic_validation': 'score_programmatic_validation',
        'tree_edit_distance': 'score_tree_edit_distance',
        'jaccard_similarity': 'score_jaccard_similarity'
    }

    set_clauses = []
    values = []

    for key, db_col in score_column_map.items():
        if key in scores_dict:
            set_clauses.append(f"{db_col} = ?")
            values.append(scores_dict[key])

    set_clauses.extend(["status = 'judged'", "judge_rationales_json = ?", "judged_at = ?"])
    values.extend([rationales_json, datetime.now().isoformat()])

    sql = f"UPDATE responses SET {', '.join(set_clauses)} WHERE row_id = ?;"
    values.append(row_id)

    cursor = conn.cursor()
    cursor.execute(sql, tuple(values))
    print(f"Successfully updated record {row_id} with judging results.")



def process_unjudged_instances(db_file, prompt_folder, model_name='gemini-2.5-pro', limit=5, do_llm=True):
    # Finds pending records, runs validation, calls the LLM judge, and updates them

    # Configure APIs and Models
    if do_llm:
        model_client = None

        if 'gemini' in model_name.lower():
            api_key = os.environ.get("GEMINI_API_KEY")
            model_client = setup_gemini(api_key)
            if not model_client:
                print("Error: Could not set up Gemini!")
                return
            
        elif 'claude' in model_name.lower():
            api_key = os.environ.get("ANTHROPIC_API_KEY")
            model_client = setup_anthropic(api_key)
            if not model_client:
                print("Error: Could not set up Anthropic!")
                return
            
        elif 'gpt' in model_name.lower():
            api_key = os.environ.get("OPENAI_API_KEY")
            if api_key:
                model_client = setup_openai(api_key)
            if not model_client:
                print("Error: Could not set up OpenAI!")
                return
        else:
            print(f"Unknown provider for: {model_name}. Exiting.")
            return

    # Find all records that need judging
    print(f"Starting judging process for up to {limit} records...")
    conn = create_connection(db_file)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM responses WHERE status = 'pending' LIMIT ?;", (limit,))
    pending_records = cursor.fetchall()

    if not pending_records:
        print("No pending records to be judged. All done!")
        conn.close()
        return

    print(f"Found {len(pending_records)} records to process.")

    for record in pending_records:

        task_name = record['task_key'].split('-')[0]

        # Map task types to their validation function
        validation_mapping = {
            'spellScripting': validate_spell_script,
            'automataScripting': validate_ca_script
        }

        # Validate the syntax of the script
        validation_status = "skipped"
        validator_func = validation_mapping.get(task_name)
        if validator_func:
            is_valid = validator_func(record['model_response'])
            validation_status = "Passed" if is_valid else "Failed"

        # If doing LLM judge
        if do_llm:

            # Find the text files containing prompts
            rules_path = os.path.join(prompt_folder, f"{task_name}_rules.txt")
            rubric_path = os.path.join(prompt_folder, f"{task_name}_rubric.txt")
            schema_path = os.path.join(prompt_folder, f"{task_name}_schema.txt")

            # We need to ensure that the judge cannot see the planning
            # If it could, it could bias the results by making the script seem
            # More well-reasoned than it is just because an articulation is present
            cleaned = record['model_response']

            try:
                data = json.loads(cleaned)
                if isinstance(data, dict) and 'planning' in data:
                    # Remove the 'planning' key
                    del data['planning']
                    cleaned = json.dumps(data)

            except json.JSONDecodeError:
                cleaned = "invalid JSON"

            # Build the prompt for the judge
            judge_prompt = build_judge_prompt(rules_path, rubric_path, schema_path, record['input'], record['context'], cleaned, validation_status)

            time.sleep(1)

            # Get the judgement
            # A low temperature helps keep the judge deterministic
            llm_response_text = None

            if 'gemini' in model_name.lower():
                llm_response_text = prompt_gemini_model(model_client, model_name, judge_prompt, 0.2)
            elif 'claude' in model_name.lower():
                llm_response_text = prompt_anthropic_model(model_client, model_name, judge_prompt, 0.2)
            elif 'gpt' in model_name.lower():
                llm_response_text = prompt_openai_model(model_client, model_name, judge_prompt, 0.2)

            if not llm_response_text:
                print(f"Skipping row_id {record['row_id']} due to an API failure.")
                continue

            try:
                judgement_data = json.loads(llm_response_text)
                scores_dict = judgement_data.get("scores", {})
                rationales_dict = judgement_data.get("rationales", {})
                
            except json.JSONDecodeError:
                print(f"Skipping row_id {record['row_id']} due to malformed JSON from LLM.")
                continue
                
            if not isinstance(scores_dict, dict) or not isinstance(rationales_dict, dict):
                print(f"Skipping row_id {record['row_id']} due to invalid JSON structure.")
                continue

        elif not do_llm:
            # Defaults if the automated judge was not run

            scores_dict = {
                'creative_alignment': 999,
                'instructional_precision': 999,
                'emergence': 999,
                'structural_coherence': 999
            }

            rationales_dict = {
                'creative_alignment': 'judgement not run for this entry',
                'instructional_precision': 'judgement not run for this entry',
                'emergence': 'judgement not run for this entry',
                'structural_coherence': 'judgement not run for this entry'
            }

        scores_dict["programmatic_validation"] = validation_status

        # Calculate similarity if there is procedural code
        if record['procedural_code']:
            print(f"Procedural code found for row_id {record['row_id']}. Calculating similarity...")
            similarity_scores = calculate_spell_similarity(record['procedural_code'], record['model_response'])
            scores_dict.update(similarity_scores)

        final_rationales_json = json.dumps(rationales_dict)
        update_judged_record(conn, record['row_id'], scores_dict, final_rationales_json)

    conn.commit()
    conn.close()
    print("Judging process finished for this batch!")
