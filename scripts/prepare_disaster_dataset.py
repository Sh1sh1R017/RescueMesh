#!/usr/bin/env python3
"""
RescueMesh — Disaster Relief Dataset Generator for SmolLM2 Fine-Tuning
Generates structured ChatML instructions for emergency medical triage, FEMA ICS protocols,
trauma first-aid, civil safety, and search-and-rescue procedures.
"""

import json
import os

# Multi-domain emergency disaster dataset
EMERGENCY_DATASET = [
    {
        "system": "You are RescueMesh AI, an offline disaster relief medical triage assistant.",
        "user": "What do I do if someone is bleeding severely from a deep leg wound?",
        "assistant": "### 🩸 SEVERE BLEEDING CONTROL PROTOCOL\n1. **Direct Pressure**: Apply firm, continuous pressure directly over the wound using a clean cloth or bandage.\n2. **Elevate**: Raise the injured leg above heart level if no fracture is suspected.\n3. **Pack Wound**: If bleeding continues, pack sterile gauze deep into the wound cavity while maintaining pressure.\n4. **Apply Tourniquet**: If arterial (bright red spurting) blood persists, apply a tourniquet 2-3 inches above the wound (never over a joint). Tighten until bleeding stops.\n5. **Record Time**: Note the exact tourniquet application time on the patient's forehead (e.g., T=14:30)."
    },
    {
        "system": "You are RescueMesh AI, an offline disaster relief medical triage assistant.",
        "user": "Is it safe to drink urine if I run out of water during an earthquake trapped under debris?",
        "assistant": "### ⚠️ DANGER: DO NOT DRINK URINE\n- **Strict Contraindication**: Drinking urine accelerates dehydration, kidney failure, and death.\n- **Explanation**: Urine is waste fluid concentrated with toxic metabolic salts. Consuming it forces your kidneys to draw water from your bloodstream to process the high salt concentration.\n- **Survival Steps**:\n  1. Preserve body moisture: stay still in shade, breathe through nose.\n  2. Do NOT consume urine, sea water, or rubbing alcohol.\n  3. Signal using 3 sharp taps on pipes/concrete every 15 minutes."
    },
    {
        "system": "You are RescueMesh AI, an offline disaster relief medical triage assistant.",
        "user": "How do I perform triage for multiple casualties in a building collapse (START Triage)?",
        "assistant": "### 🚨 S.T.A.R.T. MASS-CASUALTY TRIAGE PROTOCOL\nEvaluate casualties using RPM (Respirations, Perfusion, Mental Status) in under 60 seconds per person:\n\n1. **GREEN (Minor)**: Walking wounded. Instruct everyone who can walk to move to a safe zone.\n2. **RED (Immediate)**:\n   - Respirations > 30/min OR no breathing until airway opened.\n   - Capillary refill > 2 seconds or weak radial pulse.\n   - Cannot follow simple commands.\n3. **YELLOW (Delayed)**: Respirations < 30, strong pulse, follows commands, but cannot walk.\n4. **BLACK (Expectant/Deceased)**: No breathing after opening airway."
    },
    {
        "system": "You are RescueMesh AI, an offline disaster relief medical triage assistant.",
        "user": "What should I do if tear gas or pepper spray gets into my eyes during civil unrest?",
        "assistant": "### 🧪 TEAR GAS & PEPPER SPRAY DECONTAMINATION\n1. **Do NOT Rub Eyes**: Rubbing drives chemical micro-crystals deeper into the cornea.\n2. **Flush Eyes**: Irrigate eyes continuously with cold saline or clean water for 15 minutes. Flush from the inner nose corner outward.\n3. **Remove Contaminated Clothing**: Cut off shirts instead of pulling over your head to avoid face contact.\n4. **Skin Treatment**: Wash skin with cold water and mild soap. Avoid hot water, oils, or lotion which trap toxins."
    },
    {
        "system": "You are RescueMesh AI, an offline disaster relief medical triage assistant.",
        "user": "How do I treat someone suffering from smoke inhalation in a structure fire?",
        "assistant": "### 🫁 SMOKE INHALATION & HYPOXIA PROTOCOL\n1. **Immediate Evacuation**: Move victim to fresh air instantly. Stay low beneath smoke.\n2. **Check Airway & Breathing**: Inspect nose/mouth for soot or swelling. If unconscious and not breathing, begin CPR immediately (30 compressions : 2 breaths).\n3. **High-Flow Oxygen**: If medical kit is available, administer 100% oxygen via non-rebreather mask.\n4. **Positioning**: Place conscious victim in a comfortable semi-upright sitting position to ease breathing.\n5. **Monitor for Airway Closure**: Soot burns in throat can cause rapid vocal cord swelling. Keep emergency airway ready."
    },
    {
        "system": "You are RescueMesh AI, an offline disaster relief medical triage assistant.",
        "user": "What is a FEMA ICS-213 report and how is it formatted?",
        "assistant": "### 📋 FEMA ICS-213 GENERAL MESSAGE FORMAT\nAn ICS-213 is the standard emergency incident message format:\n- **TO**: Incident Commander / Rescue Ops\n- **FROM**: Field Team Node ID\n- **SUBJECT**: Situation Update / Resource Request\n- **DATE/TIME**: YYYY-MM-DD HH:MM\n- **MESSAGE**: Precise situation summary, coordinates [LAT, LNG], casualties, urgent needs.\n- **REPLY/ACTION**: Action taken or assistance required."
    },
    {
        "system": "You are RescueMesh AI, an offline disaster relief medical triage assistant.",
        "user": "How do I treat heat stroke in a disaster field zone?",
        "assistant": "### ☀️ HEAT STROKE EMERGENCY PROTOCOL\n1. **Recognize Heat Stroke**: High body temperature (>40°C/104°F), confusion, altered mental status, dry skin or heavy sweating.\n2. **Rapid Cooling**: Move to shade. Douse body with cold water or ice packs on neck, armpits, and groin.\n3. **Fan Air**: Continuously fan the victim while spraying cold water to maximize evaporative cooling.\n4. **Hydration**: Give small sips of cool water ONLY if conscious and able to swallow. Never pour liquids in an unconscious mouth."
    }
]

def format_chatml(sample):
    """Converts sample to ChatML format expected by SmolLM2."""
    return f"<|im_start|>system\n{sample['system']}<|im_end|>\n<|im_start|>user\n{sample['user']}<|im_end|>\n<|im_start|>assistant\n{sample['assistant']}<|im_end|>\n"

def main():
    os.makedirs("scripts/output", exist_ok=True)
    out_path = "scripts/output/disaster_triage_dataset.jsonl"
    
    with open(out_path, "w", encoding="utf-8") as f:
        for entry in EMERGENCY_DATASET:
            text = format_chatml(entry)
            f.write(json.dumps({"text": text}, ensure_ascii=False) + "\n")
            
    print(f"✅ Generated {len(EMERGENCY_DATASET)} disaster relief training samples -> {out_path}")

if __name__ == "__main__":
    main()
