# This script has functions for generating synthetic inputs to feed into the main pipeline.
# It can create spell descriptions from nothing or procedurally.
# The procedural generator randomly spreads components around in a random tree.
# It can also create groups of cellular automata material requests.

import os
import sys
import json
import random
import copy
from model_hooks import setup_gemini, prompt_gemini_model



# The following class is used internally when procedurally generating spells
class SpellGenerator:
    """
    Generates a random, valid spell JSON object using a tree approach.
    Used for Experiment 2, to assess bidirectional translation.
    """

    def __init__(self, available_elements):
        # Init the generator with the set of available magical elements
        self.elements = available_elements

    def _create_component(self, comp_type, **kwargs):
        """
        Method to create a single component with random properties.
        The ranges all come from the main game's prompt.
        **kwargs allows for nested components to be passed down for triggers.
        """

        component = {"componentType": comp_type}

        match comp_type:

            # Spell class components

            case "projectile":
                component['radius'] = round(random.uniform(2, 20), 2)
                component['speed'] = round(random.uniform(10, 20), 2)

                if random.random() < 0.3:
                    # Choice here for infinitely many bounces, which use 999
                    component["bounces"] = random.choice([random.randint(1, 5), 999])
                if random.random() < 0.4:
                    component["gravity"] = round(random.uniform(0.0, 0.5), 2)

            case "wallCrawl":
                component['radius'] = round(random.uniform(5, 15), 2)
                component['speed'] = round(random.uniform(5, 25), 2)

            case "aoe":
                component['radius'] = round(random.uniform(100, 300), 2),
                component['turns'] = random.randint(1, 10)

            case "shield":
                component['radius'] = round(random.uniform(100, 200), 2),
                component['turns'] = random.randint(1, 10)

            case "explosion":
                component["radius"] = round(random.uniform(64, 256), 2)

            case "teleportCaster":
                # Doesn't come with any params
                pass

            case "buffCaster":
                if random.random() < 0.7:
                    component["heal"] = round(random.uniform(5, 100), 2)
                if random.random() < 0.5:
                    component["resist"] = random.choice(self.elements)

                # If it's still empty after those chances, this is a default:
                if "heal" not in component and "resist" not in component:
                    component["heal"] = round(random.uniform(5, 100), 2)

            case "manifestation":
                # Manifestations currently use a simplified model compared to Alchemy Mode
                # While any automaton could be embedded here in theory, the game uses
                # a more basic system in Battle Mode to avoid having to provide 2 DSL docs at once 
                material_class = random.choice(["powder", "liquid", "gas", "solid"])

                # Spawn radius
                component['radius'] = round(random.uniform(2, 10), 2)

                # Basic material properties (required)
                component['material_properties'] = {
                    "class": material_class,
                    "color_rgb": [random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)],
                    "blockpath": random.choice([True, False]),
                    "density": random.choice([0.5, 1, 2]),
                    "elements": [random.choice(self.elements) for _ in range(random.randint(1, 2))]
                }
                
                # Optional boolean flags
                if material_class in ["liquid", "powder"] and random.random() < 0.2:
                    component["material_properties"]["viscous"] = True
                if random.random() < 0.1:
                    component["material_properties"]["zombie"] = True
                if random.random() < 0.6:
                    component["material_properties"]["harmful"] = True
                if random.random() < 0.15:
                    component["material_properties"]["lifespan"] = round(random.uniform(0.5, 30), 2)
            
            # General property components

            case "element":
                component["element"] = random.choice(self.elements)

            case "color":
                component["rgb"] = [random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)]

            case "spawnAngle":
                component["angle"] = random.randint(0, 359)

            case "spawnRandAngle":
                pass

            case "manaCost":
                component["cost"] = round(random.uniform(5, 100), 2)
            
            # Behaviour modifier components

            case "homing" | "boomerang":
                component["strength"] = round(random.uniform(0.05, 0.5), 2)

            case "controllable":
                if random.random() < 0.5:
                    component["mana_cost"] = round(random.uniform(0.01, 1), 2)
            
            # Trigger components

            case "timerTrigger" | "buttonTrigger" | "impactTrigger" | "deathTrigger":
                component["payload_components"] = kwargs.get("payload_components", [])

                # Timers have lengths and might loop a random number of times
                if comp_type == "timerTrigger":
                    component["secs"] = round(random.uniform(0.1, 5.0), 2)
                    if random.random() < 0.3:
                        component["reps"] = random.randint(2, 10)
                        component["loop"] = True

                # Any non-death trigger might optionally replace the current spell with its payload
                if comp_type in ["timerTrigger", "buttonTrigger", "impactTrigger"]:
                    if random.random() < 0.5:
                        component["replace"] = random.choice([True, False])

                # If an impact trigger doesn't replace, then it should fire more than once
                if (comp_type == "impactTrigger") and (not component.get("replace", False)) and (random.random() < 0.25):
                    component["reps"] = random.randint(1, 5)

                # Any trigger might spawn its payload multiple times
                component["count"] = random.randint(1, 5)

        return component

    def _generate_node(self, trigger_budget, component_complexity, is_payload=False):
        """
        Generates a node in the spell tree, which is a list of components.
        A node contains a primary spell class and its properties.

        Trigger budget is randomly distributed between nested levels based on nesting complexity.
        Component complexity is constant per level, so it's passed directly.
        """

        components = []
        
        # Choose one primary spell class
        # Top-level and payload spells have different main types that makes sense
        spell_class = random.choices(["projectile", "wallCrawl", "aoe", "shield", "explosion"], weights=[2, 2, 1, 1, 1], k=1)[0]
        if is_payload and random.random() < 0.7:
            spell_class = random.choice(["teleportCaster", "buffCaster", "explosion", "manifestation"])
        
        # Manifestation has unique rules, being a terminal node
        if spell_class == "manifestation":
            components.append(self._create_component("manifestation"))
            # Optional manaCost is the only other allowed component
            if random.random() < 0.75:
                components.append(self._create_component("manaCost"))
            return components, trigger_budget

        # Build the required set of components for any node
        components.append(self._create_component(spell_class))
        components.append(self._create_component("color"))
        components.append(self._create_component("element"))
        if random.random() < 0.5:
             # 1 or 2 elements per spell
             components.append(self._create_component("element"))

        # Add a random number of modifiers based on component complexity
        num_modifiers = random.randint(0, 1 + (component_complexity // 2))

        # Spawning modifiers mutually exclusive and added as one or the other
        candidates = ["homing", "boomerang", "controllable", "manaCost"]
        candidates.append(random.choice(["spawnAngle", "spawnRandAngle"]))
        modifiers_to_add = random.sample(candidates, k=min(num_modifiers, len(candidates)))

        for mod in modifiers_to_add:
            components.append(self._create_component(mod))

        # Distribute the remaining trigger budget to create child nodes
        triggers_at_this_level = 0
        if trigger_budget > 0:
            triggers_at_this_level = random.randint(1, trigger_budget)
        
        trigger_budget -= triggers_at_this_level

        # Define available trigger types, and prevent impact triggers on aoe, shield, and explosion
        available_triggers = {"timerTrigger", "buttonTrigger", "impactTrigger", "deathTrigger"}
        if spell_class in ["aoe", "shield", "explosion"]:
            available_triggers.discard("impactTrigger")

        triggers_to_add = random.sample(list(available_triggers), k=min(triggers_at_this_level, len(available_triggers)))
        
        # Loop over triggers to be added and instantiate them
        for trigger_type in triggers_to_add:
            payload_budget = 0
            if trigger_budget > 0:
                payload_budget = random.randint(1, trigger_budget)
                trigger_budget -= payload_budget
            
            # Try to pass trigger budget down, and recoup any unused budget
            payload_components, returned_budget = self._generate_node(trigger_budget=payload_budget, component_complexity=component_complexity, is_payload=True)
            trigger_budget += returned_budget

            if payload_components:
                trigger = self._create_component(trigger_type, payload_components=payload_components)
                components.append(trigger)
                
        return components, trigger_budget

    def create_spell(self, nesting_complexity=1, component_complexity=1):
        """
        Creates a complete, random spell object.
        Nesting complexity determines the number of triggers in the spell.
        Component complexity determines the number of modifiers on each node.
        """

        nesting_complexity = max(1, min(10, nesting_complexity))
        component_complexity = max(1, min(10, component_complexity))
        
        # A nesting complexity of 1 means a flat spell with 0 triggers
        trigger_count = nesting_complexity - 1

        spell = {"friendlyName": "Procedural Spell"}

        # Higher complexity (arbitrarily) increases the chance of a multicast root spell
        if nesting_complexity > 4 and random.random() < (0.1 * (nesting_complexity - 4)):
             spell["count"] = random.randint(2, (nesting_complexity // 2) + 1)
        
        # Generate the root node of the spell tree
        spell['components'], _ = self._generate_node(
            trigger_budget=trigger_count, 
            component_complexity=component_complexity
        )

        return spell
    


# The following functions are exposed to the main notebook



def generate_spell_tasks_procedural(num_tasks=10, min_nesting=1, max_nesting=5, min_components=1, max_components=5, output_file="spell_scripting_tasks.json", model_name='gemini-2.5-pro'):
    """
    Generates synthetic spellScripting tasks by creating procedural spells
    and prompting a model to describe them. Uses the SpellGenerator class.
    """

    # Load the Gemini API key
    api_key = os.getenv("GEMINI_API_KEY")
    gemini_client = setup_gemini(api_key)
    if not gemini_client:
        print("Failed to configure the Gemini API!")
        sys.exit(1)

    # Define a master list of possible magical elements
    master_element_list = [
        "fire", "water", "earth", "air", "lightning", "ice", "light", "shadow",
        "poison", "acid", "force", "gravity", "time", "space", "mind", "spirit",
        "nature", "metal", "wood", "sound", "aether", "nether", "blood", "bone",
        "celestial", "void", "sand", "steam", "crystal", "dream", "fear", "chaos",
        "order", "life", "death", "arcane", "rune", "illusion", "distortion"
    ]

    final_tasks = []
    print(f"Generating {num_tasks} procedural spells...")

    for i in range(num_tasks):
        print(f" - Generating base spell {i+1}/{num_tasks}...")

        # Select a random subset of elements for this spell's context
        num_elements_to_select = random.randint(5, 10)
        available_elements = random.sample(master_element_list, num_elements_to_select)
            
        # Procedurally generate a single spell
        spell_generator = SpellGenerator(available_elements=available_elements)
        nesting_complexity = random.randint(min_nesting, max_nesting)
        component_complexity = random.randint(min_components, max_components)
        procedural_spell = spell_generator.create_spell(nesting_complexity, component_complexity)
        spell_json_string = json.dumps(procedural_spell, indent=2)

        # Define the 4 prompt templates for the 2x2 factorial design
        # This hijacks the description length variable; not the cleanest solution,
        # but I didn't want to re-do the database schema again and migrate everything over

        # 1 - Technical, Summary
        # 2 - Technical, Detailed
        # 3 - Narrative, Summary
        # 4 - Narrative, Detailed

        prompts = {
            1: ("technical_summary", f"""
                You are a game designer writing a concise tooltip for a spell.
                Your description must be a single, clear sentence summarising the spell's primary effect.
                Omit precise numerical values.

                Spell JSON:
                {spell_json_string}
            """),

            2: ("technical_detailed", f"""
                You are a technical writer documenting a spell's mechanics.
                Provide a clear, step-by-step breakdown of the spell's execution sequence.
                You must include all relevant numerical values (radius, secs, cost, etc.).
                Use headings like "On Cast:" and "After X seconds:" to structure the phases.

                Spell JSON:
                {spell_json_string}
            """),

            3: ("narrative_summary", f"""
                You are an imaginative fantasy loremaster writing flavor text for a spell.
                Your description must be a single, thematic sentence that evokes the spell's feeling and primary outcome.
                Do not include specific numbers.

                Spell JSON:
                {spell_json_string}
            """),

            4: ("narrative_detailed", f"""
                You are an imaginative fantasy loremaster describing what a spell looks like.
                Write a thematic, multi-sentence description of the spell's effects as a sequence of events.
                Creatively interpret the JSON and describe what the spell looks and feels like in a fantasy world.

                Spell JSON:
                {spell_json_string}
            """)
        }

        # For each spell, generate all 4 description types
        for code, (name, prompt_text) in prompts.items():
            print(f"generating description for: {name} (code: {code})")

            # I went with 0.8 temp for creativity
            spell_description = prompt_gemini_model(gemini_client, model_name, prompt_text, temperature=0.8).strip()
                
            # Create the final task object
            task_pair = {
                "input": spell_description,
                "context": available_elements,
                "metadata": {
                    "procedural": int(1),
                    "procedural_spell": procedural_spell,
                    "nesting_complexity": nesting_complexity,
                    "component_complexity": component_complexity,
                    "max_sentences_for_desc": code
                }
            }
            final_tasks.append(task_pair)

    with open(output_file, 'w') as f:
        json.dump(final_tasks, f, indent=2)
        
    print(f"\nSaved {len(final_tasks)} spellScripting tasks to {output_file}")



def generate_spell_tasks_ex_nihilo(num_tasks=10, max_sentences=3, output_file="spell_scripting_tasks.json", model_name='gemini-2.5-flash'):
    """
    Generates synthetic spellScripting tasks by prompting a model to create
    spell descriptions fully from scratch (ex nihilo).
    """

    # Load the Gemini API key
    api_key = os.getenv("GEMINI_API_KEY")
    gemini_client = setup_gemini(api_key)
    if not gemini_client:
        print("Failed to configure the Gemini API!")
        sys.exit(1)

    # Define a master list of possible magical elements
    master_element_list = [
        "fire", "water", "earth", "air", "lightning", "ice", "light", "shadow",
        "poison", "acid", "force", "gravity", "time", "space", "mind", "spirit",
        "nature", "metal", "wood", "sound", "aether", "nether", "blood", "bone",
        "celestial", "void", "sand", "steam", "crystal", "dream", "fear", "chaos",
        "order", "life", "death", "arcane", "rune", "illusion", "distortion"
    ]

    # Single prompt to generate all descriptions at once for efficiency
    description_prompt = f"""
    You are an imaginative fantasy loremaster. Your task is to invent a list of exactly {num_tasks} unique and creative descriptions of magical spells.

    Each description should:
    - Be action-oriented, describing a sequence of events or effects.
    - Be no more than {max_sentences} sentences long.
    - Be suitable for a fantasy game context.

    Return your response as a single JSON object with one key, "spell_descriptions", which contains a list of the {num_tasks} strings you generated.
    """

    print(f"Sending prompt to generate {num_tasks} descriptions...")
    final_tasks = []

    # Make a request to get all descriptions
    response_text = prompt_gemini_model(gemini_client, model_name, description_prompt, temperature=0.9)
    response_data = json.loads(response_text)
    spell_descriptions = response_data.get("spell_descriptions", [])

    if not spell_descriptions or len(spell_descriptions) != num_tasks:
        print(f"Error: Expected {num_tasks}, got {len(spell_descriptions)}.")
        return

    print(f"Received {len(spell_descriptions)} descriptions.")

    # Process each  description
    for desc in spell_descriptions:
        num_elements_to_select = random.randint(5, 10)
        available_elements = random.sample(master_element_list, num_elements_to_select)
            
        # Create the final task object
        task_pair = {
            "input": desc,
            "context": available_elements,
            "metadata": {
                "procedural": int(0),
                "max_sentences_for_desc": max_sentences
            }
        }
        final_tasks.append(task_pair)

    # Write the final list of tasks to the output file
    with open(output_file, 'w') as f:
        json.dump(final_tasks, f, indent=2)
        
    print(f"\nSaved {len(final_tasks)} spellScripting tasks to {output_file}")



def generate_automata_scripting_tasks(num_systems=5, num_tasks_per_system=4, output_file="automata_scripting_tasks.json", model_name='gemini-2.5-flash'):
    """
    Generates synthetic automata scripting tasks.
    Individual material descriptions are given within a theme, to encourage interaction.

    This process has two stages:
    1 - It prompts the model once to get a list of unique biome themes.
    2 - It then iterates through that list, prompting the model to generate a set of
        materials for each theme.
    """

    # Define basic context (sand, air, etc)
    context_json_string = """
    {"sand":{"actions":[{"actions":[{"direction":"south","actions":[{"direction":"south","type":"do_swap"}],"else_actions":[{"direction":"southeast","actions":[{"direction":"southeast","type":"do_swap"}],"type":"if_neighbor_is","options":["air","gas","water"]}],"type":"if_neighbor_is","options":["air","gas","water"]}],"type":"in_rand_mirror"}]},"water":{"actions":[{"actions":[{"direction":"south","actions":[{"direction":"south","type":"do_swap"}],"else_actions":[{"direction":"southeast","actions":[{"direction":"southeast","type":"do_swap"}],"else_actions":[{"direction":"east","actions":[{"direction":"east","type":"do_swap"}],"type":"if_neighbor_is","options":["air","gas"]}],"type":"if_neighbor_is","options":["air","gas"]}],"type":"if_neighbor_is","options":["air","gas"]}],"type":"in_rand_mirror"}]},"gas":{"actions":[{"actions":[{"direction":"north","actions":[{"direction":"north","type":"do_swap"}],"type":"if_neighbor_is","options":["air"]}],"type":"in_rand_rotation"}]}}
    """
    base_automata_context = json.loads(context_json_string)

    # Configure Gemini
    api_key = os.getenv("GEMINI_API_KEY")
    gemini_client = setup_gemini(api_key)
    if not gemini_client:
        print("Failed to configure the Gemini API!")
        sys.exit(1)

    final_tasks = []

    # Generate a batch of unique themes
    print(f"Requesting a list of {num_systems} themes...")
        
    theme_prompt = f"""
    You are a creative world-builder. Your task is to invent a list of unique biomes or environmental themes for a 2D falling-sand simulation game.
    Please provide a list of exactly {num_systems} distinct themes.
    Focus on grounded, natural themes. For example: "Shoreline", "Desert Oasis", "Alpine Forest", "Mangrove Swamp", or "Cavern".
    Avoid overly fantastical or abstract themes like "Plane of Nightmares" or "The Void".
    Return your response as a single JSON object with one key, "themes", which contains a list of strings.
    Example: {{"themes": ["Tidal Pool", "Riverbank", "Volcanic Plains"]}}
    """
        
    # Prompt the model
    response = prompt_gemini_model(gemini_client, model_name, theme_prompt, temperature=0.7)
    themes_list = json.loads(response)['themes']

    if not themes_list or len(themes_list) != num_systems:
        print(f"Expected {num_systems} themes, got {len(themes_list)}. Aborting.")
        sys.exit(1)

    print(f"Received themes: {', '.join(themes_list)}")

    # Iterate through themes and generate materials
    for theme in themes_list:
        print(f"\nGenerating system for theme: '{theme}'")

        material_prompt = f"""
        You are a game designer creating materials for a 2D falling-sand cellular automata simulation.
        Your goal is to describe a thematic set of materials for the following theme: {theme}.
        The materials should have interesting potential interactions and feel like they belong together.
        For example, for a "Shoreline" theme, you might create Saltwater, Wet Sand, Dry Sand, and Seafoam.
        Now, generate a list of exactly {num_tasks_per_system} material descriptions for the "{theme}" theme.
        Return your response as a single JSON object with one key, "descriptions", which contains a list of dictionaries, each with a "material_name" and a "behavior_description".
        """

        # Prompt the model
        material_response = prompt_gemini_model(gemini_client, model_name, material_prompt, temperature=0.8)
        response_data = json.loads(material_response)
        material_data = response_data.get("descriptions", [])

        if not material_data or len(material_data) != num_tasks_per_system:
            print(f"Model returned an unexpected format or number of descriptions!")
            continue

        print(f"Received {len(material_data)} material descriptions.")
        
        # Build up context for each new material within a theme
        # This is necessary so that the models can create interactions
        current_context = copy.deepcopy(base_automata_context)
        for item in material_data:
            material_name = item.get("material_name", "unknown").lower().replace(" ", "_")
            behavior_description = item.get("behavior_description")
                
            task_pair = {
                "input": behavior_description,
                "context": copy.deepcopy(current_context),
                "theme": theme
            }
            final_tasks.append(task_pair)
                
            current_context[material_name] = {"actions": [{"type": "placeholder"}]}

    # Save final results
    with open(output_file, 'w') as f:
        json.dump(final_tasks, f, indent=2)
            
    print(f"\nSaved {len(final_tasks)} tasks to {output_file}")
