import os

with open("mock_data.txt", "r") as f:
    mock_data = f.read()

service_path = r"lib\web_app_template\general_factory_setting\equipment_category\services\equipment_category_service.dart"

with open(service_path, "r") as f:
    content = f.read()

start_marker = "    // Returning mocked data based on the PDF"
end_marker = "    ];\n  }"

start_idx = content.find(start_marker)
end_idx = content.find(end_marker) + len(end_marker)

if start_idx != -1 and end_idx != -1:
    new_content = content[:start_idx] + mock_data.strip() + "\n  }" + content[end_idx:]
    with open(service_path, "w") as f:
        f.write(new_content)
    print("Replaced mock data.")
else:
    print("Could not find markers.")
