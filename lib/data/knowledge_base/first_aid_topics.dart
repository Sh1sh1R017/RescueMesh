import '../../domain/models/first_aid_topic.dart';

/// Static offline knowledge base of 14 comprehensive first-aid protocols.
const List<FirstAidTopic> kFirstAidTopics = [
  // ─────────────────────────────────────────────
  // 0. IMPROVISED MATERIALS GUIDE
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Improvised First Aid — What to Use Around You',
    category: 'Field Improvisation',
    summary:
        'In a disaster or riot, you will NOT have a medical kit. Everything below is a real substitute that has been used successfully in field conditions. Know these before you need them.',
    steps: [
      '🩹 BANDAGE / DRESSING → Use: clean T-shirt, torn bedsheet, socks, scarves, or any fabric that is as clean as possible. Avoid fluffy fabrics (towels, wool) on open wounds — fibres stick.',
      '🩸 WOUND PACKING → Use: torn strips of cotton clothing packed firmly into the cavity. A menstrual pad (sanitary pad) is highly absorbent and nearly sterile — excellent for wound coverage.',
      '🫀 TOURNIQUET → Use: a belt, zip tie (on small limbs), torn strip of denim or canvas at least 4 cm wide. NEVER use rope, wire, or thin cord — they cut through tissue. Tighten with a stick or pen twisted through a loop (windlass technique).',
      '🧊 ICE PACK → Use: a sealed bag of frozen peas, frozen water bottle wrapped in cloth, or any cold wet cloth. Wrap in fabric — never apply ice directly to skin.',
      '🔩 SPLINT → Use: wooden boards, thick cardboard, rolled-up newspaper or magazine, an umbrella, or a walking stick. Pad it with folded clothing to prevent pressure sores.',
      '🪢 SLING (arm/shoulder) → Use: a jacket (zip or button it around the neck to cradle the arm), a large scarf, or a triangle cut from any large piece of fabric.',
      '💧 WOUND IRRIGATION / EYE FLUSH → Use: bottled water, sports drinks (if nothing else), or rainwater. Pour copiously — volume matters more than sterility for flushing. Avoid carbonated drinks on open wounds.',
      '🧤 GLOVES → Use: plastic bags over your hands, rubber gloves from a cleaning kit, or double-layered latex gloves. If nothing available, reduce direct contact by using multiple layers of cloth.',
      '🛡️ EYE SHIELD (penetrating wound) → Use: bottom of a foam/paper cup, a folded piece of cardboard taped around the eye without touching it. Never use a flat pad that presses on the eyeball.',
      '🌡️ HYPOTHERMIA / HEAT RETENTION → Use: foil crisp packets (space blanket alternative), bubble wrap, newspapers stuffed inside clothing, bin bags as windbreakers.',
      '🩼 STRETCHER / CARRY → Use: a sturdy jacket with sleeves turned inside out and two strong poles threaded through, a strong tarpaulin or tent, a wooden door, or a blanket held at four corners (requires 4 people).',
      '🔥 BURN COVER → Use: kitchen cling wrap (plastic film) laid flat (not wrapped tightly) over the burn. Excellent — clean, non-stick, and retains moisture. Also clean bin bags as emergency cover.',
      '🫁 CHEST SEAL (sucking chest wound) → Use: any plastic wrapper (crisp packet, zip-lock bag) cut to size and taped on THREE sides only — this creates a one-way valve. The fourth open side allows air to escape on exhale.',
      '🧂 ORAL REHYDRATION SOLUTION (ORS) → Mix: 1 litre clean water + 6 teaspoons sugar + ½ teaspoon salt. Stir until dissolved. Effective against dehydration and heat exhaustion when no sports drinks available.',
      '💊 PAIN RELIEF → Paracetamol (acetaminophen) found in most households/shops. Ibuprofen for inflammation but AVOID for head injuries, suspected internal bleeding, or shock. AVOID aspirin for trauma — it worsens bleeding.',
      '🔦 LIGHT SOURCE → Phone torch, candle, lighter flame (sterilize needles to drain blisters by passing briefly through flame).',
      '✂️ CUTTING → Pocket knife, scissors from a sewing kit, box cutters, or broken glass wrapped in cloth as a handle to cut away clothing from wounds.',
    ],
    contraindications: [
      'Do NOT use alcohol (vodka, hand sanitizer) directly inside wounds — it kills healing tissue and worsens damage. Use it on the SKIN AROUND the wound only to clean scissors/tools.',
      'Do NOT use toothpaste, butter, oil, mayonnaise, or egg white on burns — all trap heat and introduce bacteria.',
      'Do NOT use fluffy towels or wool directly on open wounds — fibres embed in the wound.',
      'Do NOT use rope, wire, or shoelaces as tourniquets — only wide, flat materials.',
      'Do NOT use dirty water to irrigate eyes if clean water is nearby — but dirty water in large volumes is better than no irrigation at all for chemical exposure.',
    ],
    whenToEvacuate: [
      'Improvised materials buy time — they are not a substitute for professional medical care.',
      'All wounds treated with improvised materials should be reassessed by medical staff as soon as possible.',
    ],
    keywords: [
      'improvise', 'improvised', 'available', 'found', 'around', 'substitute',
      'no kit', 'no equipment', 'no supplies', 'disaster', 'riot', 'emergency',
      'makeshift', 'field', 'everyday', 'common', 'household', 'scarf', 'shirt',
      'belt', 'plastic', 'bottle', 'what can i use', 'without', 'instead of',
    ],
  ),

  // ─────────────────────────────────────────────
  // 1. TEAR GAS & PEPPER SPRAY
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Tear Gas & Pepper Spray Exposure',
    category: 'Chemical Agents',
    summary:
        'CS gas, OC spray, and pepper spray are chemical irritants causing intense burning in eyes, nose, throat, lungs, and skin. Effects last 15–30 minutes. Move away from the source immediately.',
    steps: [
      'MOVE immediately upwind and uphill to fresh air. Chemical agents sink, so get to higher ground.',
      'Stay CALM and breathe slowly through the nose if possible to reduce inhalation.',
      'EYES: Blink rapidly to generate tears and flush the agent out. Do not rub.',
      'Flush eyes with CLEAN WATER or saline (0.9% NaCl) for at least 15–20 minutes, pouring from the inner corner outward.',
      'SKIN: Remove contaminated clothing as quickly as possible. Cut off shirts if needed to avoid dragging over the face.',
      'Wash exposed skin with large amounts of COLD soapy water. Cold water keeps pores closed.',
      'NOSE & MOUTH: Blow your nose, spit, and cough repeatedly. Do not swallow.',
      'Rinse mouth with clean water and spit — do not swallow.',
      'If eyelids are swollen shut, gently open them under running water.',
      'After decontamination, apply a cool damp cloth to the face for comfort.',
    ],
    contraindications: [
      'Do NOT rub eyes or skin — this grinds chemical crystals deeper into tissue.',
      'Do NOT use MILK — it is not sterile, traps active chemicals on the surface, and risks eye infection.',
      'Do NOT use warm or hot water — it opens pores and worsens absorption.',
      'Do NOT wear contact lenses to a protest — tear gas concentrates behind the lens causing corneal scarring.',
      'Do NOT use antacid solutions (Maalox/baking soda) — insufficient evidence and may cause extra irritation.',
    ],
    whenToEvacuate: [
      'Persistent vision loss or severe eye pain after flushing.',
      'Difficulty breathing or wheezing not resolving after 20 minutes in fresh air.',
      'Signs of allergic reaction: hives, swelling of face/throat, difficulty swallowing.',
      'Chest pain or loss of consciousness.',
    ],
    keywords: [
      'tear gas', 'pepper spray', 'gas', 'spray', 'cs gas', 'oc spray',
      'mace', 'eyes burning', 'blinded', 'chemical', 'smoke', 'irritant',
      'flush', 'canister', 'grenade',
    ],
  ),

  // ─────────────────────────────────────────────
  // 2. SEVERE BLEEDING
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Severe & Life-Threatening Bleeding',
    category: 'Trauma — Hemorrhage Control',
    summary:
        'Uncontrolled bleeding from major arteries can be fatal in 3–5 minutes. Rapid hemorrhage control is the single most important skill in field trauma care. Act immediately.',
    steps: [
      'PUT ON GLOVES if available to protect yourself from bloodborne pathogens.',
      'EXPOSE the wound by cutting away clothing — do not waste time untying.',
      'DIRECT PRESSURE: Apply firm, continuous pressure using a clean cloth, gauze, or gloved hand.',
      'Press down HARD — use your full body weight. Maintain pressure for a MINIMUM of 5 minutes without lifting.',
      'If blood soaks through, DO NOT lift the dressing. Add more layers on top and continue pressing.',
      'TOURNIQUET (limb wounds only): Apply 5–8 cm (2–3 inches) ABOVE the wound if direct pressure fails. Never on a joint.',
      'Tighten the tourniquet until bleeding STOPS. Note the exact time applied — write on forehead or limb.',
      'WOUND PACKING (groin, armpit, neck): Pack the cavity tightly with gauze or clean cloth. Apply direct pressure over the pack.',
      'Keep the casualty WARM — hypothermia worsens blood clotting.',
      'Elevate legs 30 cm if no spinal injury suspected — helps maintain blood pressure.',
      'Keep talking to the patient calmly. Unconscious: put in recovery position.',
    ],
    contraindications: [
      'Do NOT remove a tourniquet once applied — risk of fatal re-hemorrhage.',
      'Do NOT apply a tourniquet over clothing — it must contact skin.',
      'Do NOT apply a tourniquet on the neck, torso, or groin — use wound packing.',
      'Do NOT use thin material (rope, wire, belt) — use only wide (4–5 cm) straps.',
    ],
    whenToEvacuate: [
      'All significant bleeding wounds require medical evaluation.',
      'Any tourniquet application — causes tissue damage after 1–2 hours.',
      'Suspected internal bleeding: rigid or painful abdomen, unexplained bruising.',
      'Patient is pale, cool, sweating, confused, or losing consciousness (shock).',
    ],
    keywords: [
      'bleeding', 'blood', 'cut', 'wound', 'gash', 'tourniquet', 'pressure',
      'stab', 'hemorrhage', 'artery', 'vein', 'laceration', 'deep cut', 'severed',
    ],
  ),

  // ─────────────────────────────────────────────
  // 3. RUBBER BULLETS / KINETIC IMPACT
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Rubber Bullet & Kinetic Impact Wounds',
    category: 'Impact Trauma',
    summary:
        'Rubber bullets can cause severe blunt force trauma, penetrating wounds, internal organ damage, bone fractures, and death — especially at close range or to the head, neck, or groin.',
    steps: [
      'CHECK for responsiveness. Call the person\'s name and tap their shoulder.',
      'AIRWAY: Tilt chin up and check for breathing. If not breathing, begin CPR.',
      'EXPOSE the impact site — remove or cut away clothing.',
      'ASSESS: Look for skin breaks, deformity (fracture), or crepitus (bone grinding).',
      'SKIN BREAK: Treat as open wound — clean with water, apply sterile dressing, apply pressure.',
      'SUSPECTED FRACTURE: Immobilize in position found. Splint above and below fracture.',
      'CHEST HIT: Watch breathing. Sucking wound from chest wall — cover with plastic wrap taped on 3 sides.',
      'HEAD HIT: Treat as traumatic brain injury. Keep patient still. Monitor consciousness. Do NOT let them sleep unmonitored.',
      'GROIN/ABDOMEN HIT: Assume internal injury. Lay flat, bend knees, cover abdomen. No food or water.',
      'Control external bleeding with direct pressure.',
      'Treat for shock: keep warm, elevate feet, reassure.',
    ],
    contraindications: [
      'Do NOT assume a wound is minor because the skin is unbroken — internal injuries can be fatal.',
      'Do NOT try to straighten a deformed limb — immobilize it in position found.',
      'Do NOT remove embedded objects — stabilize them in place with padding.',
      'Do NOT give aspirin for pain — it thins blood and worsens bleeding.',
    ],
    whenToEvacuate: [
      'ANY head, neck, or eye impact — immediate medical evaluation needed.',
      'Chest hit with breathing difficulty — tension pneumothorax is life-threatening.',
      'Abdominal hit with increasing pain, rigidity, or vomiting.',
      'Loss of consciousness at any point.',
      'Any suspected spinal injury — do not move without proper immobilization.',
    ],
    keywords: [
      'rubber bullet', 'bullet', 'impact', 'baton', 'projectile', 'bruise',
      'blunt', 'kinetic', 'pellet', 'hit', 'struck', 'shot', 'bean bag', 'flashbang',
    ],
  ),

  // ─────────────────────────────────────────────
  // 4. HEAT STROKE & DEHYDRATION
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Heat Stroke, Heat Exhaustion & Dehydration',
    category: 'Environmental — Hyperthermia',
    summary:
        'Heat exhaustion is the warning stage. Heat stroke is life-threatening — body temperature above 40°C (104°F) causes brain damage and death if not cooled rapidly.',
    steps: [
      'MOVE the person to shade or coolest available area immediately.',
      'DISTINGUISH: Heat exhaustion = heavy sweating, cool pale skin, dizziness, normal mental status. Heat stroke = hot DRY skin OR confusion, slurred speech, seizures. Heat stroke is an emergency.',
      'COOL IMMEDIATELY for heat stroke: Remove outer clothing. Soak with water and fan vigorously. Apply ice packs to neck, armpits, and groin.',
      'If ice is available, pack it around the body without causing violent shivering.',
      'LAY DOWN with legs elevated about 30 cm unless difficulty breathing.',
      'If CONSCIOUS and swallowing safely: cool water or electrolyte drink in small sips.',
      'MONITOR: Check breathing and responsiveness every 2 minutes.',
      'If VOMITING: turn onto their side (recovery position) to prevent choking.',
      'Continue cooling until help arrives or patient clearly improves.',
      'For dehydration only: rest, rehydrate with small frequent sips, add electrolytes.',
    ],
    contraindications: [
      'Do NOT give fluids to an unconscious person — risk of aspiration.',
      'Do NOT over-cool to violent shivering — shivering generates internal heat.',
      'Do NOT give alcohol — worsens dehydration.',
      'Do NOT leave them alone.',
    ],
    whenToEvacuate: [
      'Altered consciousness, confusion, or seizures — heat stroke emergency.',
      'Absence of sweating combined with hot skin in heat.',
      'Unconsciousness or failure to improve after 15–20 minutes of cooling.',
    ],
    keywords: [
      'heat', 'hot', 'sun', 'faint', 'dizzy', 'dehydrated', 'water', 'passed out',
      'unconscious', 'exhaustion', 'heat stroke', 'sweating', 'overheated', 'thirsty',
      'cramping', 'sunstroke',
    ],
  ),

  // ─────────────────────────────────────────────
  // 5. CROWD CRUSH & COMPRESSIVE ASPHYXIA
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Crowd Crush & Compressive Asphyxia',
    category: 'Crowd Trauma',
    summary:
        'Crowd crush is a silent killer. Pressure from surrounding crowds compresses the chest, preventing breathing (compressive asphyxia). Death can occur within minutes even while upright.',
    steps: [
      'PERSONAL SAFETY: If you feel pushing, turn sideways and brace forearms up (boxing guard) to create a chest air pocket.',
      'Move with the crowd flow — never fight directly against it. Move diagonally toward exits.',
      'If you fall, CURL into fetal position protecting your head and airway with arms until you can rise.',
      'FOR A VICTIM: Move to open space immediately — every second of compression worsens injury.',
      'ASSESS breathing: crushed patients may have labored or absent breathing even after release.',
      'Open the AIRWAY: tilt head, lift chin. Look, listen, feel for breathing.',
      'If not breathing: start CPR. 30 compressions then 2 rescue breaths.',
      'If breathing but unconscious: recovery position on their side.',
      'Watch for TRAUMATIC ASPHYXIA: blood spots in whites of eyes, blue face/neck — severe compression injury.',
      'Keep patient calm and still. Respiratory distress may worsen even after decompression.',
      'Yell "PUSH BACK! PUSH BACK!" loudly if someone falls — bystanders often don\'t realize what is happening.',
    ],
    contraindications: [
      'Do NOT carry a crush victim through an active crowd — wait for an opening.',
      'Do NOT give food or water to a significantly crushed patient before medical assessment.',
    ],
    whenToEvacuate: [
      'All crush victims need medical evaluation regardless of appearance.',
      'Unconsciousness at any point.',
      'Coughing blood or extreme respiratory distress.',
      'Visible signs of traumatic asphyxia (burst blood vessels in eyes, facial discoloration).',
    ],
    keywords: [
      'crowd', 'crush', 'stampede', 'trampled', 'compressed', 'suffocate',
      'asphyxia', 'pushed', 'fell', 'fallen', 'crowd surge', 'kettle', 'cordon',
    ],
  ),

  // ─────────────────────────────────────────────
  // 6. HEAD INJURIES & CONCUSSION
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Head Injury & Concussion',
    category: 'Neurological Trauma',
    summary:
        'Head injuries from batons, falls, or projectiles can cause concussion, brain bleeding, or skull fractures. Even someone who appears fine may deteriorate rapidly — the "talk and die" phenomenon.',
    steps: [
      'ASSESS consciousness: Ask their name, where they are, what day it is. Confusion is a red flag.',
      'Control SCALP BLEEDING with firm direct pressure — scalp wounds bleed heavily but don\'t indicate brain injury severity.',
      'Do NOT apply pressure if you feel a depression or skull deformity — use a donut-shaped pad around it.',
      'ASSUME SPINAL INJURY if mechanism was significant (fall, direct strike). Keep head and neck still.',
      'If unconscious and vomiting: MUST move to recovery position to prevent choking — minimize neck movement.',
      'SERIOUS SIGNS: loss of consciousness, seizure, unequal pupils, fluid from nose/ear, worsening headache, vomiting more than once, increasing confusion.',
      'CONCUSSION (mild): rest in quiet dark area, no screens, no physical activity, monitor closely.',
      'Keep patient awake and talking. Monitor every 15 minutes.',
      'Pain relief: paracetamol/acetaminophen ONLY. No aspirin or ibuprofen.',
    ],
    contraindications: [
      'Do NOT let a concussed person return to the crowd or physical activity.',
      'Do NOT leave them unmonitored — "talk and die" can happen within hours.',
      'Do NOT give aspirin or ibuprofen — increases bleeding risk.',
      'Do NOT apply pressure over suspected skull fractures.',
    ],
    whenToEvacuate: [
      'Any loss of consciousness however brief.',
      'Seizure activity.',
      'Unequal pupil size or pupils not responding to light.',
      'Fluid from ear or nose (possible skull base fracture).',
      'Repeated vomiting.',
      'Worsening or severe headache.',
      'Slurred speech, weakness, or numbness in limbs.',
    ],
    keywords: [
      'head', 'skull', 'brain', 'concussion', 'hit head', 'baton', 'head injury',
      'headache', 'dizzy', 'confused', 'unconscious', 'knocked out', 'seizure',
      'unequal pupils', 'TBI',
    ],
  ),

  // ─────────────────────────────────────────────
  // 7. EYE INJURIES
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Eye Injuries — Projectiles, Chemicals & Trauma',
    category: 'Eye Trauma',
    summary:
        'Eye injuries at protests include chemical exposure, blunt trauma from projectiles, and penetrating injuries from rubber bullets. Eye injuries can cause permanent blindness.',
    steps: [
      'CHEMICAL EXPOSURE: Flush immediately with large volumes of clean water or saline for 15–20 minutes. Hold eye open under running water. Remove contact lenses.',
      'BLUNT TRAUMA (no open wound): Apply cold wet cloth gently over closed eye. Do NOT press firmly. Keep both eyes closed.',
      'PENETRATING WOUND (embedded object): DO NOT attempt to remove. Cover eye loosely with paper cup or cardboard shield. Cover BOTH eyes.',
      'SUBCONJUNCTIVAL HEMORRHAGE (red eye): Alarming but resolves in 2 weeks. Cold compress, no rubbing.',
      'CONTACT LENSES: Remove immediately if chemical exposure. If stuck after trauma, do NOT force it — seek medical care.',
      'Cover BOTH eyes even if only one is injured — they move together.',
      'Keep patient calm, sitting or lying still.',
      'Note TIME of injury and mechanism for medical report.',
    ],
    contraindications: [
      'Do NOT rub the eye under any circumstances.',
      'Do NOT press on a penetrating eye wound — pushes object deeper.',
      'Do NOT wear contact lenses to a protest.',
      'Do NOT use eye drops other than saline.',
      'Do NOT patch both eyes shut tightly if penetrating wound — use a shield, not a pad.',
    ],
    whenToEvacuate: [
      'All penetrating eye injuries — act fast to preserve sight.',
      'Significant blunt trauma to the eye.',
      'Vision loss or blurring that does not clear.',
      'Severe pain or photosensitivity.',
      'Chemical exposure not rapidly improving after flushing.',
    ],
    keywords: [
      'eye', 'eyes', 'vision', 'blind', 'blinded', 'eye injury', 'eye pain',
      'contact lens', 'rubber bullet eye', 'pepper spray eyes', 'can\'t see',
    ],
  ),

  // ─────────────────────────────────────────────
  // 8. FRACTURES & DISLOCATIONS
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Bone Fractures & Dislocations',
    category: 'Musculoskeletal Trauma',
    summary:
        'Fractures result from falls, baton strikes, or crowd crush. Open fractures where bone protrudes carry high infection and bleeding risk. Dislocations occur when joints are forced out of position.',
    steps: [
      'STOP BLEEDING first if there is an open fracture — gentle pressure AROUND the wound, not directly on bone.',
      'DO NOT attempt to straighten or reduce the fracture. Immobilize in the POSITION FOUND.',
      'SPLINTING: Place rigid support (plank, rolled magazine, cardboard) along the limb past the joints ABOVE and BELOW the fracture.',
      'Pad the splint with clothing to prevent pressure sores.',
      'Secure with bandages or torn fabric. Check circulation — fingers/toes should be warm with capillary refill.',
      'OPEN FRACTURE: Cover exposed bone with clean wet cloth. Do NOT push bone back in.',
      'DISLOCATIONS: Immobilize the joint in most comfortable position. Do NOT attempt to put it back.',
      'ANKLE/FOOT: Keep shoe on as splint. RICE: Rest, Ice, Compression, Elevation.',
      'COLLARBONE: Support arm in sling (fabric triangle) close to the body.',
      'Check circulation every 15 minutes — warmth, capillary refill, sensation.',
    ],
    contraindications: [
      'Do NOT attempt to reduce (pop back) dislocations in the field.',
      'Do NOT straighten a deformed limb.',
      'Do NOT remove a shoe if foot fracture suspected — it acts as a splint.',
      'Do NOT ignore circulation checks — compartment syndrome can cause permanent disability.',
    ],
    whenToEvacuate: [
      'All fractures require X-ray and medical management.',
      'Open fractures are surgical emergencies.',
      'Any neurovascular compromise distal to the fracture.',
      'Suspected femur (thigh) fracture — can cause 1–2 litre internal blood loss.',
      'Suspected spinal fracture.',
    ],
    keywords: [
      'fracture', 'broken', 'bone', 'snap', 'crack', 'break', 'dislocated',
      'dislocation', 'splint', 'arm', 'leg', 'ankle', 'wrist', 'shoulder',
      'collarbone', 'swollen',
    ],
  ),

  // ─────────────────────────────────────────────
  // 9. BURNS (CHEMICAL & THERMAL)
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Burns — Chemical & Thermal',
    category: 'Burns',
    summary:
        'Burns result from chemical agents, fire, or hot liquids. Severity: 1st = redness, 2nd = blisters, 3rd = charred/numb. Act within the first minutes to reduce depth.',
    steps: [
      'CHEMICAL BURNS: Brush off dry powder first. Flush continuously with cool running water for 20+ minutes. Remove contaminated clothing.',
      'THERMAL BURNS: Cool under cool (not ice cold) running water for at least 20 minutes.',
      'REMOVE jewellery and clothing around burn BEFORE swelling starts.',
      'ASSESS size: patient\'s palm = approx. 1% body surface area.',
      'COVER with clean non-fluffy material. Cling wrap (kitchen film) is ideal — lay flat, do not wrap tightly.',
      'PAIN MANAGEMENT: Paracetamol/acetaminophen if available.',
      'KEEP WARM: Burns cause heat loss — cover patient with blanket away from burn site.',
      'Do NOT pop blisters — they protect tissue from infection.',
      'Give fluids if conscious and burns cover more than 10% body surface area.',
    ],
    contraindications: [
      'Do NOT use ice or ice water — worsens burn depth.',
      'Do NOT apply butter, toothpaste, oil, or any home remedy.',
      'Do NOT use fluffy materials like cotton wool — fibres stick to the wound.',
      'Do NOT try to neutralize chemical burns with acids/bases — the reaction produces heat.',
      'Do NOT pop blisters.',
    ],
    whenToEvacuate: [
      'Burns larger than patient\'s palm.',
      'Burns involving the face, hands, feet, genitals, or joints.',
      'Any full thickness (3rd degree) burn.',
      'Burns in children or elderly.',
      'Inhalation burns: singed nose hairs, soot in mouth, hoarse voice.',
      'All chemical burns.',
    ],
    keywords: [
      'burn', 'fire', 'flame', 'burned', 'chemical burn', 'blister', 'scalded',
      'scorched', 'molotov', 'flare', 'incendiary',
    ],
  ),

  // ─────────────────────────────────────────────
  // 10. PANIC ATTACKS & MENTAL HEALTH
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Panic Attacks & Acute Stress Reactions',
    category: 'Mental Health & Psychological First Aid',
    summary:
        'Panic attacks feel like a heart attack but are not life-threatening. Key symptoms: racing heart, shortness of breath, chest tightness, dizziness, tingling in hands, overwhelming fear.',
    steps: [
      'MOVE AWAY: Guide the person away from the crowd to a quieter space.',
      'INTRODUCE YOURSELF calmly: "My name is [X]. You are safe. I am here to help you."',
      'GROUNDING — 5-4-3-2-1: Name 5 things you can see, 4 you can touch, 3 you can hear, 2 you can smell, 1 you can taste.',
      'BREATHING: Breathe IN for 4 counts, HOLD for 4, OUT for 6. Ask them to match you.',
      'Physical touch: Ask permission first. A firm hand on shoulder or holding their hand can help.',
      'REASSURE: "This is a panic attack. It is not dangerous. It will pass in a few minutes."',
      'GIVE SPACE: One calm person is best — do not crowd them.',
      'After the attack passes, sit with them for a few minutes and offer water.',
      'Do not force them to return to the crowd immediately.',
    ],
    contraindications: [
      'Do NOT say "calm down", "stop panicking", or "you are fine" — dismisses their experience.',
      'Do NOT leave them alone — worsens panic.',
      'Do NOT give unnecessary information or stimulation during the attack.',
      'Do NOT assume it is a panic attack if the person has chest pain and is over 40 — consider cardiac.',
    ],
    whenToEvacuate: [
      'Chest pain with left arm pain, jaw pain, or heavy sweating — could be cardiac.',
      'Loss of consciousness.',
      'Confusion persisting more than 15 minutes.',
      'Pre-existing psychiatric conditions being exacerbated.',
    ],
    keywords: [
      'panic', 'anxiety', 'fear', 'scared', 'hyperventilating', 'heart racing',
      'stress', 'ptsd', 'trauma', 'shaking', 'trembling', 'flashback', 'mental', 'breakdown',
    ],
  ),

  // ─────────────────────────────────────────────
  // 11. HYPOTHERMIA
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Hypothermia — Dangerous Cold',
    category: 'Environmental — Cold',
    summary:
        'Hypothermia occurs when core temperature drops below 35°C (95°F). It can happen even in mild temperatures (10–15°C) if the person is wet, exhausted, or stationary.',
    steps: [
      'Move the person out of cold and wind — into a building or sheltered area.',
      'Handle GENTLY — a hypothermic heart is irritable and rough movement can trigger fatal arrhythmia.',
      'REMOVE wet clothing carefully and replace with dry layers.',
      'INSULATE from ground — lay on sleeping bag, coats, or any insulating material.',
      'Cover the HEAD — up to 40% of heat loss is through the head.',
      'Apply chemical heat packs or warm (not hot) water bottles to armpits, neck, and groin. Wrap in cloth first.',
      'If conscious and able to swallow: warm sweet drinks. NO alcohol.',
      'If shivering: good sign — body still generating heat. Keep insulating.',
      'If NOT shivering and confused or unconscious: severe hypothermia — evacuate urgently.',
    ],
    contraindications: [
      'Do NOT rub limbs vigorously — brings cold blood to the core.',
      'Do NOT give alcohol — causes vasodilation and worsens heat loss.',
      'Do NOT apply direct heat on skin — use cloth-wrapped heat sources.',
      'Do NOT assume death — hypothermic patients have survived with no detectable pulse.',
    ],
    whenToEvacuate: [
      'Not shivering despite being cold — severe hypothermia.',
      'Loss of consciousness or near-unconsciousness.',
      'Cardiac arrhythmia or absent pulse.',
    ],
    keywords: [
      'cold', 'freezing', 'hypothermia', 'shivering', 'numb', 'pale', 'blue lips',
      'temperature', 'rain', 'wet', 'exposed',
    ],
  ),

  // ─────────────────────────────────────────────
  // 12. CPR & CARDIAC ARREST
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'CPR & Cardiac Arrest',
    category: 'Life Support',
    summary:
        'Cardiac arrest means the heart has stopped pumping. Brain death begins in 4–6 minutes without CPR. You CANNOT harm someone in cardiac arrest — they are already dying. Start CPR immediately.',
    steps: [
      'CHECK responsiveness: shout their name, tap shoulders firmly. No response — call for help loudly.',
      'LOOK for normal breathing no more than 10 seconds. Occasional gasping is NOT normal breathing.',
      'CHEST COMPRESSIONS: Heel of one hand on centre of chest (lower half of sternum). Other hand on top, fingers interlaced.',
      'Compress HARD and FAST: at least 5–6 cm (2–2.5 inches) deep, 100–120 per minute (beat of "Stayin\' Alive" by Bee Gees).',
      'ALLOW full chest recoil after each compression — do not lean on chest.',
      'RESCUE BREATHS (if trained): After 30 compressions, tilt head, lift chin, pinch nose, give 2 breaths watching for chest rise.',
      'COMPRESSION-ONLY CPR: If not trained or unable to give breaths, continuous compressions alone still significantly improve survival.',
      'SWITCH compressors every 2 minutes to maintain quality.',
      'CONTINUE until: person shows signs of life, an AED is available, or you cannot continue.',
      'AED: Turn on, follow voice prompts. Continue CPR while pads placed. Stand clear ONLY when prompted to shock.',
    ],
    contraindications: [
      'Do NOT waste time checking for a pulse if unresponsive and not breathing normally.',
      'Do NOT stop CPR unless clear signs of life appear.',
      'Do NOT be afraid — you cannot make things worse for someone in cardiac arrest.',
    ],
    whenToEvacuate: [
      'Cardiac arrest — evacuation IS the goal. Continue CPR during transport.',
    ],
    keywords: [
      'cardiac arrest', 'heart attack', 'cpr', 'no pulse', 'not breathing',
      'unconscious', 'resuscitation', 'compressions', 'rescue breath', 'aed',
      'defibrillator', 'heart stopped', 'collapse', 'unresponsive',
    ],
  ),

  // ─────────────────────────────────────────────
  // 13. LEGAL RIGHTS (PROTEST)
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Legal Rights During a Protest & Arrest',
    category: 'Legal Safety',
    summary:
        'Knowing your legal rights can prevent unnecessary escalation and protect you legally. These are general principles — laws vary by country and jurisdiction.',
    steps: [
      'BEFORE the protest: Write legal aid numbers and emergency contacts on your ARM in permanent marker — phones get seized.',
      'DOCUMENT: Know the protest permit number if one exists. Note which agencies are policing.',
      'IF APPROACHED by police: Stay calm. Keep hands visible. No sudden movements.',
      'You have the right to ask: "AM I BEING DETAINED?" — If no, you may leave.',
      'IF DETAINED: Ask "AM I UNDER ARREST AND WHAT IS THE CHARGE?" — Police must give a reason.',
      'EXERCISE RIGHT TO SILENCE: "I am invoking my right to remain silent. I want a lawyer." Then say NOTHING further.',
      'DO NOT CONSENT to searches — say "I do not consent to this search" clearly but do not physically resist.',
      'IF ARRESTED: Stay calm. Do not resist physically even if the arrest is unlawful — challenge it legally later.',
      'In custody: Right to contact a lawyer before answering questions in most jurisdictions.',
      'DO NOT sign any documents without legal counsel present.',
      'OBSERVERS: You may legally observe and record in most jurisdictions from a safe distance.',
      'AFTER RELEASE: Document everything — officer badge numbers, time, location, witnesses.',
    ],
    contraindications: [
      'Do NOT physically resist arrest — results in additional charges and injury.',
      'Do NOT give a false name or identity documents.',
      'Do NOT discuss events with other arrestees — conversations can be monitored.',
      'Do NOT post about the incident on social media until you have spoken to a lawyer.',
    ],
    whenToEvacuate: [
      'If you witness violence against a detained person, note details but prioritize your own safety.',
    ],
    keywords: [
      'rights', 'police', 'arrest', 'arrested', 'lawyer', 'cop', 'detained',
      'detention', 'search', 'legal', 'law', 'charges', 'warrant', 'badge',
      'officer', 'silent', 'attorney', 'custody', 'kettling', 'mass arrest',
    ],
  ),

  // ─────────────────────────────────────────────
  // 14. PROTEST PREPARATION
  // ─────────────────────────────────────────────
  FirstAidTopic(
    title: 'Protest Preparation & Safety Gear',
    category: 'Prevention & Preparation',
    summary:
        'Being well-prepared before the protest is the most effective form of first aid. Proper gear and planning prevents most injuries.',
    steps: [
      'BUDDY SYSTEM: Never go alone. Arrange check-in schedule and a meeting point if separated.',
      'CLOTHING: Long sleeves and pants. Natural fibres (cotton) better than synthetic. Flat closed-toe shoes only.',
      'EYES: Splash-proof goggles or glasses. Never contact lenses — tear gas traps behind them.',
      'FACE: N95 mask or respirator. Wet cloth reduces (not eliminates) chemical exposure.',
      'COMMUNICATION: Fully charged phone, portable charger, written backup numbers.',
      'FIRST AID KIT: Saline eyewash, nitrile gloves, gauze, bandages, tourniquet, medical tape, pain relief, antihistamine.',
      'HYDRATION: Carry at least 1 litre of water. Eat before attending.',
      'MEDICATIONS: Bring prescription medications for the day. Know your allergies.',
      'EXTRACTION PLAN: Know at least 3 exit routes. Identify medic station locations.',
      'IF THREATENED: Move with crowd flow, not against it. Head for edges, not the middle.',
    ],
    contraindications: [],
    whenToEvacuate: [
      'Trust your instincts — leave early rather than too late.',
      'If you see crowd crush developing, move to the edge immediately.',
    ],
    keywords: [
      'preparation', 'prepare', 'gear', 'kit', 'plan', 'safety', 'goggles',
      'mask', 'buddy', 'clothing', 'what to bring', 'what to wear', 'checklist',
      'first aid kit', 'equipment',
    ],
  ),
];
