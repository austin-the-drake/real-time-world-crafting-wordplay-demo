# This script handles the model prompting, mirroring the game's process.
# It dynamically builds up prompts from text files, interfaces with the various LLMs,
# and creates session log files in the same format as the game.

import os
import sys
import time
import json
from datetime import datetime
from model_hooks import setup_anthropic, setup_gemini, setup_openai, prompt_anthropic_model, prompt_gemini_model, prompt_openai_model



def format_prompt(preamble, task_input, task_context):
    #Formats the final prompt string to be sent to the model

    context_str = json.dumps(task_context, indent=2)
    
    # Prompts consist of a preamble (docs, examples, etc), the current request, and context
    return f"""{preamble}

    User input to fulfil
    {task_input}

    Relevant context
    ```json
    {context_str}
    ```
    """



def format_log_entry(task_type, task_input, task_context, model_response_text, task_metadata=None):
    """ 
    Formats a single entry for the output log file to match the game.
    The game initially used .ini files, but switched to text files later on.
    There are some clunky holdovers, like section headers retaining the square brackets.
    """

    # Header
    timestamp = datetime.now().strftime('%Y-%m-%d-%H-%M-%S')
    header = f"[{task_type}-{timestamp}]"

    # Context and response
    context_str = json.dumps(task_context)
    response_str = model_response_text
    

    # Build the section up
    log_parts = [
        header,
        f"input::{task_input}",
        f"context::{context_str}"
    ]

    if task_metadata:
        metadata_str = json.dumps(task_metadata)
        log_parts.append(f"metadata::{metadata_str}")

    log_parts.append(f"response::{response_str}")
    
    # This section separator is how the game outputs them
    return "\n".join(log_parts) + "\n[end]\n"



def run_prompting_session(task_type, model_name, prompt_preamble, input_json_file, output_log_dir, delay=0):
    """
    Runs a prompting session by processing tasks from a given JSON file with a specified model.

    This function automates reading task data, setting up the appropriate
    API, generating prompts, sending them to the model, and
    logging the entire interaction to a log file. Each task's result is
    written to the log file immediately after it is processed to avoid lost work.

    Args:
        task_type (str): A descriptor for the task being performed.
        model_name (str): The identifier for the model to be prompted.
        prompt_preamble (str): The static portion of the prompt.
        input_json_file (str): The file path to a JSON file containing a list of task objects.
        output_log_dir (str): The path to the directory where the session log file will be saved.
    """

    print("Starting new prompting session...")
    print(f"Task type: {task_type}")
    print(f"Model: {model_name}")
    print(f"Input file: {input_json_file}\n")

    # Load input data
    with open(input_json_file, 'r') as f:
        tasks = json.load(f)
    print(f"Loaded {len(tasks)} tasks from {input_json_file}.")

    # Prepare output log file
    os.makedirs(output_log_dir, exist_ok=True)
    session_timestamp = datetime.now().strftime('%Y-%m-%d-%H-%M-%S')
    safe_model_name = model_name.replace("/", "_")
    log_filename = f"LatentSpaceLog-{safe_model_name}-{session_timestamp}.txt"
    log_filepath = os.path.join(output_log_dir, log_filename)
    print(f"Will write results to: {log_filepath}\n")
    
    # Setup APIs based on model type
    api_client = None
    if ('gemini' in model_name.lower()) or ('gemma' in model_name.lower()):
        api_key = os.getenv("GEMINI_API_KEY")
        api_client = setup_gemini(api_key)
        if not api_client:
            sys.exit("Failed to configure Gemini API.")

    elif 'gpt' in model_name.lower():
        api_key = os.getenv("OPENAI_API_KEY")
        api_client = setup_openai(api_key)
        if not api_client:
            sys.exit("Failed to configure OpenAI API.")

    elif 'claude' in model_name.lower():
        api_key = os.getenv("ANTHROPIC_API_KEY")
        api_client = setup_anthropic(api_key)
        if not api_client:
            sys.exit("Failed to configure Anthropic API.")

    else:
        sys.exit(f"Unknown model provider for {model_name}.")

    # Process each task and write to log
    with open(log_filepath, 'w', encoding='utf-8') as log_file:
        for i, task in enumerate(tasks):
            
            print(f"Processing task {i+1}/{len(tasks)}...")
            task_input = task.get('input', '')
            task_context = task.get('context', {})
            task_metadata = task.get('metadata')

            full_prompt = format_prompt(prompt_preamble, task_input, task_context)
            
            # Delaying as necessary because of rate limits
            time.sleep(delay)

            # Model prompt
            response_text = ""
            if (('gemini' in model_name.lower()) or ('gemma' in model_name.lower())) and api_client:
                response_text = prompt_gemini_model(api_client, model_name, full_prompt, 0.7)

            elif 'gpt' in model_name.lower() and api_client:
                response_text = prompt_openai_model(api_client, model_name, full_prompt, 0.7)

            elif 'claude' in model_name.lower() and api_client:
                response_text = prompt_anthropic_model(api_client, model_name, full_prompt, 0.7)
            else:
                print(f"Unknown model provider for {model_name}. Skipping...")
                response_text = json.dumps({"error": f"Unknown model provider for {model_name}"})

            # Format and write the log entry
            log_entry = format_log_entry(task_type, task_input, task_context, response_text, task_metadata)
            log_file.write(log_entry)
    
    print(f"All {len(tasks)} tasks have been processed and logged to {log_filepath}.")