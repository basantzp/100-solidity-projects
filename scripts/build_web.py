#!/usr/bin/env python3
import os
import re
import json

def main():
    os.makedirs("web", exist_ok=True)
    with open("README.md", "r", encoding="utf-8") as f:
        readme = f.read()

    lines = readme.splitlines()
    projects = []

    current_pillar = "Pillar 01: Foundational Tokens & ERC Standards"
    pillar_map = {
        1: "Pillar 01: Tokens & Standards",
        2: "Pillar 02: Custody & Access Control",
        3: "Pillar 03: AMMs & DEX Primitives",
        4: "Pillar 04: Lending & Yield",
        5: "Pillar 05: Cryptography & ZK",
        6: "Pillar 06: Advanced EVM & Cancun",
        7: "Pillar 07: Upgradeability & Proxies",
        8: "Pillar 08: DAOs & Governance",
        9: "Pillar 09: Account Abstraction",
        10: "Pillar 10: Cross-Chain & MEV"
    }

    row_regex = re.compile(r"\|\s*\*\*#(\d+)\*\*\s*\|\s*\[`([^`]+)`\]\(([^)]+)\)\s*\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|")

    for line in lines:
        match = row_regex.search(line)
        if match:
            p_id = int(match.group(1))
            file_name = match.group(2).strip()
            src_path = match.group(3).strip()
            category = match.group(4).strip()
            innovation = match.group(5).strip()
            gas_profile = match.group(6).strip()

            base_name = file_name.replace(".sol", "")
            test_path = f"test/{base_name}.t.sol"

            src_code = ""
            if os.path.exists(src_path):
                with open(src_path, "r", encoding="utf-8") as sf:
                    src_code = sf.read()

            test_code = ""
            if os.path.exists(test_path):
                with open(test_path, "r", encoding="utf-8") as tf:
                    test_code = tf.read()

            pillar_num = (p_id - 1) // 10 + 1
            pillar_name = pillar_map.get(pillar_num, f"Pillar {pillar_num}")

            projects.append({
                "id": p_id,
                "name": base_name,
                "fileName": file_name,
                "srcPath": src_path,
                "testPath": test_path,
                "pillar": pillar_name,
                "pillarNum": pillar_num,
                "category": category,
                "innovation": innovation,
                "gasProfile": gas_profile,
                "testCommand": f"forge test --match-contract {base_name}Test -vv",
                "srcCode": src_code,
                "testCode": test_code
            })

    print(f"Loaded {len(projects)} projects.")
    with open("web/projects-data.js", "w", encoding="utf-8") as out:
        out.write("window.PROJECTS_DATA = ")
        json.dump(projects, out, indent=2)
        out.write(";\n")
    print("Successfully generated web/projects-data.js")

if __name__ == "__main__":
    main()
