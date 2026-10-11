with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "'Piggy AI Advisor'" in line:
        # Cerchiamo all'indietro nelle 5 righe precedenti la 'const Column('
        for j in range(i, max(-1, i-6), -1):
            if 'const Column(' in lines[j]:
                lines[j] = lines[j].replace('const Column(', 'Column(')
                print(f"🧹 Rimosso 'const' alla riga {j+1}")
                
                # Aggiungiamo const ai figli successivi per mantenere le performance
                for k in range(i+2, i+6):
                    if "'• Online • Voce & Desideri'" in lines[k]:
                        lines[k-1] = lines[k-1].replace('Text(', 'const Text(')
                break
        break

lines.append('\n// Fix const per tema dinamico AI v1.3.17\n')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ Modificatore 'const' rimosso chirurgicamente!")
