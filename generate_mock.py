import re

with open("pdf_output.txt", "r", encoding="utf-16le") as f:
    lines = f.read().splitlines()

# Extract part 1: Device Type, Device Code, Equipment Category
part1 = []
for line in lines[1:32]:
    match = re.match(r'^(\d+)(.*?)\s+([A-Z]+)\s+(.*)$', line.strip())
    if match:
        idx = match.group(1)
        device_type = match.group(2).strip()
        device_code = match.group(3).strip()
        equip_category = match.group(4).strip()
        part1.append({"idx": idx, "type": device_type, "code": device_code, "cat": equip_category})

# Extract part 2: Category Code, Electrical Parent, OEE Module, Energy Module
part2 = []
start_idx = lines.index("Category Code Electrical Parent OEE Module Energy Module") + 1
for line in lines[start_idx:]:
    if line.startswith("Device Type Master List"): continue
    if not line.strip(): continue
    
    parts = line.split()
    cat_code = parts[0]
    energy = parts[-1]
    oee = parts[-2]
    parent = " ".join(parts[1:-2])
    
    part2.append({"cat_code": cat_code, "parent": parent, "oee": oee, "energy": energy})

if len(part1) == len(part2):
    print("      // Returning mocked data based on the PDF")
    print("      return [")
    for i in range(len(part1)):
        d1 = part1[i]
        d2 = part2[i]
        
        oee_val = d2['oee'].capitalize()
        energy_val = d2['energy'].capitalize()
        
        print("        {")
        print(f"          'id': '{d1['idx']}',")
        print(f"          'device_type': '{d1['type']}',")
        print(f"          'device_code': '{d1['code']}',")
        print(f"          'equipment_category': '{d1['cat']}',")
        print(f"          'category_code': '{d2['cat_code']}',")
        print(f"          'electrical_parent': '{d2['parent']}',")
        print(f"          'oee_module': '{oee_val}',")
        print(f"          'energy_module': '{energy_val}',")
        print("        },")
    print("      ];")
else:
    print(f"Mismatch: len(part1)={len(part1)}, len(part2)={len(part2)}")
