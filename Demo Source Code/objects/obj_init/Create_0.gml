/// @description Init LLM

// Production behaviour (safe)
randomize();

// Can be set to "gemini", "openai", "anthropic"
global.api = "anthropic";
global.gemini_cred = "";
global.anthropic_cred = "";
global.openai_cred = "";
global.key = global.anthropic_cred;