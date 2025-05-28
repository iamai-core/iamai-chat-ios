from flask import Flask, request, jsonify
from flask_cors import CORS
from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline
import logging

#logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  #enable CORS

model = None
tokenizer = None
text_gen_pipeline = None

def initialize_model():
    """Initialize the model, tokenizer, and pipeline"""
    global model, tokenizer, text_gen_pipeline
    
    logger.info("Loading model...")
    huggingface_model = "TinyLlama/TinyLlama-1.1B-Chat-v1.0"
    
    try:
        model = AutoModelForCausalLM.from_pretrained(huggingface_model)
        tokenizer = AutoTokenizer.from_pretrained(huggingface_model)
        
        text_gen_pipeline = pipeline(
            "text-generation",
            model=model,
            tokenizer=tokenizer,
            max_new_tokens=200,
            do_sample=True,
            temperature=0.7,
            pad_token_id=tokenizer.eos_token_id,
        )
        logger.info("Model loaded successfully!")
        return True
    except Exception as e:
        logger.error(f"Error loading model: {e}")
        return False

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "model_loaded": text_gen_pipeline is not None})

@app.route('/chat', methods=['POST'])
def chat():
    """Main chat endpoint"""
    try:
        if text_gen_pipeline is None:
            return jsonify({"error": "Model not loaded"}), 500
        
        data = request.get_json()
        if not data or 'message' not in data:
            return jsonify({"error": "No message provided"}), 400
        
        user_message = data['message']
        logger.info(f"Received message: {user_message}")
        
        #format prompt
        prompt = f"<|system|>\nYou are a helpful assistant.</s>\n<|user|>\n{user_message}</s>\n<|assistant|>\n"
        
        #get response
        response = text_gen_pipeline(prompt)
        generated_text = response[0]['generated_text']
        
        #clean response
        if generated_text.startswith(prompt):
            ai_response = generated_text[len(prompt):].strip()
        else:
            ai_response = generated_text.strip()
        
        #fallback
        if not ai_response:
            ai_response = "I'm not sure how to respond to that."
        
        logger.info(f"Generated response: {ai_response}")
        
        return jsonify({
            "response": ai_response,
            "status": "success"
        })
        
    except Exception as e:
        logger.error(f"Error generating response: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/models', methods=['GET'])
def get_model_info():
    """Get information about the loaded model"""
    if text_gen_pipeline is None:
        return jsonify({"error": "Model not loaded"}), 500
    
    return jsonify({
        "model": "meta-llama/Llama-3.2-1B",
        "status": "loaded",
        "max_tokens": 200
    })

if __name__ == '__main__':
    print("Starting AI Server...")
    
    #initialize model
    if initialize_model():
        print("✅ Model loaded successfully!")
        print("🚀 Starting server on http://localhost:8090")
        print("📱 Your iOS app can now connect to: http://localhost:8090/chat")
        app.run(host='0.0.0.0', port=8090, debug=False)
    else:
        print("❌ Failed to load model. Server not started.")