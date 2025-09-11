import json
import os
from google import genai
import openai
import anthropic

def _strip_markdown_wrappers(text):
    """
    Strips the markdown code block wrappers from a string, if they exist.
    It's inconsistent whether these models do this or not, so both the game and
    this analysis code try to check for them.
    """
        
    stripped_text = text.strip()
    
    # Check if the text is wrapped in markdown code blocks
    if stripped_text.startswith("```") and stripped_text.endswith("```"):
        # Find the first newline to handle cases like ```json
        first_newline_index = stripped_text.find('\n')
        
        if first_newline_index != -1:
            # Extract content after the first line and before the final ```
            cleaned_text = stripped_text[first_newline_index + 1:-3].strip()
        else:
            # This handles a single line case
            cleaned_text = stripped_text[3:-3].strip()
        
        return cleaned_text

    # If not wrapped in markdown, return
    return stripped_text



# Gemini



def setup_gemini(api_key):
    # Configures the Gemini API and returns a client instance

    try:
        client = genai.Client(api_key=api_key)
        return client
    
    except Exception as e:
        print(f"Error configuring Gemini client: {e}")
        return None

def prompt_gemini_model(client, model_name, full_prompt, temperature):
    """
    Sends a prompt to a given Gemini model and returns the response text.

    Args:
        client (google.genai.client.Client): The Gemini client instance.
        model_name (str): The name of the Gemini model to use.
        full_prompt (str): The complete prompt to send to the model.
        temperature (float): The sampling temperature to use.

    Returns:
        str: The cleaned text content of the model's response.
    """

    try:
        response = client.models.generate_content(
            model=model_name,
            contents=full_prompt,
            config={'temperature': temperature}
        )
        print(f"Success: Received response from model.")
        # Clean the response before returning
        return _strip_markdown_wrappers(response.text)
    
    except Exception as e:
        print(f"ERROR: An error occurred during Gemini API call: {e}")
        return json.dumps({"error": str(e)})



# OpenAI



def setup_openai(api_key):
    # Configures the OpenAI API and returns a client instance

    try:
        client = openai.OpenAI(api_key=api_key)
        return client
    
    except Exception as e:
        print(f"Error configuring OpenAI client: {e}")
        return None

def prompt_openai_model(client, model_name, full_prompt, temperature):
    """
    Sends a prompt to a given OpenAI model and returns the response text.

    Args:
        client (openai.OpenAI): The OpenAI client instance.
        model_name (str): The name of the OpenAI model to use.
        full_prompt (str): The complete prompt to send to the model.
        temperature (float): The sampling temperature to use.

    Returns:
        str: The cleaned text content of the model's response.
    """

    try:
        response = client.chat.completions.create(
            model=model_name,
            messages=[
                {"role": "user", "content": full_prompt}
            ],
            temperature=temperature
        )
        print(f"Success: Received response from model.")
        # Clean the response before returning
        return _strip_markdown_wrappers(response.choices[0].message.content)
    
    except Exception as e:
        print(f"ERROR: An error occurred during OpenAI API call: {e}")
        return json.dumps({"error": str(e)})



# Anthropic



def setup_anthropic(api_key):
    # Configures the Anthropic API and returns a client instance
    try:
        client = anthropic.Anthropic(api_key=api_key)
        return client
    
    except Exception as e:
        print(f"Error configuring Anthropic client: {e}")
        return None

def prompt_anthropic_model(client, model_name, full_prompt, temperature):
    """
    Sends a prompt to a given Anthropic model and returns the response text.

    Args:
        client (anthropic.Anthropic): The Anthropic client instance.
        model_name (str): The name of the Anthropic model to use.
        full_prompt (str): The complete prompt to send to the model.
        temperature (float): The sampling temperature to use.

    Returns:
        str: The cleaned text content of the model's response.
    """

    try:
        message = client.messages.create(
            model=model_name,
            max_tokens=4096,
            messages=[
                {"role": "user", "content": full_prompt}
            ],
            temperature=temperature
        )
        print(f"Success: Received response from model.")
        
        response_text = message.content[0].text
        # Clean the response before returning
        return _strip_markdown_wrappers(response_text)

    except Exception as e:
        print(f"ERROR: An error occurred during Anthropic API call: {e}")
        return json.dumps({"error": str(e)})







if __name__ == "__main__":
    gemini_client = setup_gemini(os.getenv("GEMINI_API_KEY"))
    if gemini_client:
        response_text = prompt_gemini_model(gemini_client, 'gemma-3-4b-it', "This is a test prompt. Please respond with 'Hello World!'", 0.7)
        print(response_text)