#!/usr/bin/env python3
"""
RescueMesh — Fine-Tune SmolLM2 for Disaster Relief & Emergency Triage
Fine-tunes HuggingFaceTB/SmolLM2-360M-Instruct or SmolLM2-135M-Instruct using PEFT LoRA / SFTTrainer.

Usage:
  python train_smollm_disaster.py --model_id HuggingFaceTB/SmolLM2-360M-Instruct --epochs 3
"""

import argparse
import os
import torch
from datasets import load_dataset
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    TrainingArguments,
)
from peft import LoraConfig, get_peft_model
from trl import SFTTrainer

def parse_args():
    parser = argparse.ArgumentParser(description="Fine-tune SmolLM2 for RescueMesh Disaster Triage")
    parser.add_argument("--model_id", type=str, default="HuggingFaceTB/SmolLM2-360M-Instruct", help="Base model ID")
    parser.add_argument("--dataset_path", type=str, default="scripts/output/disaster_triage_dataset.jsonl", help="Dataset path")
    parser.add_argument("--output_dir", type=str, default="scripts/output/SmolLM2-360M-DisasterTriage", help="Output model directory")
    parser.add_argument("--epochs", type=int, default=5, help="Number of training epochs")
    parser.add_argument("--batch_size", type=int, default=4, help="Batch size per GPU")
    parser.add_argument("--learning_rate", type=float, default=2e-4, help="Learning rate")
    return parser.parse_args()

def train():
    args = parse_args()
    print(f"🚀 Initializing Fine-Tuning for model: {args.model_id}")

    # 1. Load Dataset
    dataset = load_dataset("json", data_files=args.dataset_path, split="train")

    # 2. Load Tokenizer & Model
    tokenizer = AutoTokenizer.from_pretrained(args.model_id, trust_remote_code=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    device_map = "auto" if torch.cuda.is_available() else "cpu"
    torch_dtype = torch.bfloat16 if torch.cuda.is_available() and torch.cuda.is_bf16_supported() else torch.float32

    model = AutoModelForCausalLM.from_pretrained(
        args.model_id,
        torch_dtype=torch_dtype,
        device_map=device_map,
        trust_remote_code=True,
    )

    # 3. Configure LoRA (Low-Rank Adaptation for ultra-fast training)
    peft_config = LoraConfig(
        r=16,
        lora_alpha=32,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        lora_dropout=0.05,
        bias="none",
        task_type="CAUSAL_LM",
    )

    model = get_peft_model(model, peft_config)
    model.print_trainable_parameters()

    # 4. Training Arguments
    training_args = TrainingArguments(
        output_dir=args.output_dir,
        per_device_train_batch_size=args.batch_size,
        gradient_accumulation_steps=2,
        learning_rate=args.learning_rate,
        num_train_epochs=args.epochs,
        logging_steps=10,
        save_strategy="epoch",
        fp16=torch.cuda.is_available() and not torch.cuda.is_bf16_supported(),
        bf16=torch.cuda.is_available() and torch.cuda.is_bf16_supported(),
        optim="adamw_torch",
        report_to="none",
    )

    # 5. SFT Trainer
    trainer = SFTTrainer(
        model=model,
        train_dataset=dataset,
        peft_config=peft_config,
        dataset_text_field="text",
        max_seq_length=512,
        tokenizer=tokenizer,
        args=training_args,
    )

    print("⚡ Starting Training Pass...")
    trainer.train()

    # 6. Save Merged Fine-Tuned Weights
    final_output = os.path.join(args.output_dir, "final_merged_model")
    print(f"💾 Merging LoRA weights & saving fine-tuned model to: {final_output}")
    merged_model = trainer.model.merge_and_unload()
    merged_model.save_pretrained(final_output)
    tokenizer.save_pretrained(final_output)

    print(f"🎉 SUCCESS: SmolLM2 Disaster Triage Model ready at {final_output}")

if __name__ == "__main__":
    train()
