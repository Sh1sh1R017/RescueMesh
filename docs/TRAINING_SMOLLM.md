# 🧠 RESCUEMESH — SMOLLM2 DISASTER RELIEF FINE-TUNING GUIDE

This guide provides step-by-step instructions to fine-tune **HuggingFace SmolLM2** (`SmolLM2-135M-Instruct` or `SmolLM2-360M-Instruct`) specifically for off-grid disaster medical triage, emergency first aid, FEMA protocols, and search-and-rescue assistance.

---

## ⚡ 1. Fast Training on Google Colab (Free GPU)

You can run the entire training pipeline for free in **Google Colab** (T4 GPU instance).

### Colab One-Click Setup Commands

```bash
# 1. Clone RescueMesh repository
!git clone https://github.com/Sh1sh1R017/RescueMesh.git
%cd RescueMesh

# 2. Install PyTorch & Fine-Tuning Toolchain
!pip install -q transformers peft trl datasets accelerate bitsandbytes

# 3. Generate Disaster Triage Training Dataset
!python3 scripts/prepare_disaster_dataset.py

# 4. Run SmolLM2 Fine-Tuning (360M Parameter Model)
!python3 scripts/train_smollm_disaster.py \
    --model_id HuggingFaceTB/SmolLM2-360M-Instruct \
    --epochs 5 \
    --batch_size 4

# 5. Export to GGUF (Q4_K_M) for RescueMesh Mobile App
!bash scripts/export_to_gguf.sh
```

---

## 🏗️ 2. Local Training Pipeline

If you have a local GPU (NVIDIA RTX 2060+, GTX 1660, or Apple Silicon Mac):

```bash
# Install dependencies
pip install transformers peft trl datasets accelerate

# Step A: Prepare Dataset
python3 scripts/prepare_disaster_dataset.py

# Step B: Train Model
python3 scripts/train_smollm_disaster.py \
    --model_id HuggingFaceTB/SmolLM2-360M-Instruct \
    --output_dir scripts/output/SmolLM2-360M-DisasterTriage

# Step C: Export GGUF
bash scripts/export_to_gguf.sh
```

---

## 📲 3. Deploying Your Trained Model to RescueMesh

1. Take the generated file:  
   `scripts/output/SmolLM2-360M-DisasterTriage-Q4_K_M.gguf`
2. Place it on your local web server / mesh router or phone storage:  
   `d:\RescueMesh-main\releases\SmolLM2-360M-Instruct-Q4_K_M.gguf`
3. Launch RescueMesh $\rightarrow$ Open **Settings** $\rightarrow$ Tap **Load Best SmolLM2 Model**!
