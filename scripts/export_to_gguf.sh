#!/usr/bin/env bash
# RescueMesh — Convert Fine-Tuned SmolLM2 Model to GGUF format for Mobile Execution

set -e

MODEL_PATH="scripts/output/SmolLM2-360M-DisasterTriage/final_merged_model"
OUTPUT_GGUF="scripts/output/SmolLM2-360M-DisasterTriage-Q4_K_M.gguf"

echo "📦 Converting HF Model to GGUF format..."

if [ ! -d "llama.cpp" ]; then
  echo "Cloning llama.cpp repository..."
  git clone https://github.com/ggerganov/llama.cpp.git
  cd llama.cpp && make -j4 && cd ..
fi

python3 llama.cpp/convert_hf_to_gguf.py "$MODEL_PATH" --outfile "scripts/output/model_f16.gguf" --outtype f16

echo "⚡ Quantizing GGUF model to Q4_K_M for RescueMesh Edge AI engine..."
./llama.cpp/llama-quantize "scripts/output/model_f16.gguf" "$OUTPUT_GGUF" Q4_K_M

echo "🎉 DONE: GGUF Model exported to $OUTPUT_GGUF"
