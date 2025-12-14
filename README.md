# PWM Generator System (Verilog)

Acest proiect implementează un generator de semnal PWM (Pulse Width Modulation) configurabil, scris în Verilog (standard IEEE 1364-2005). Sistemul este controlat printr-o interfață **SPI Slave** și include protecții avansate pentru trecerea între domenii de ceas (Clock Domain Crossing - CDC).

## 📂 Structura Proiectului

| Fișier | Descriere |
| :--- | :--- |
| **`top.v`** | Modulul de top-level care interconectează toate sub-modulele. |
| **`spi_bridge.v`** | Interfața SPI Slave. Gestionează sincronizarea datelor între ceasul SPI (`sclk`) și ceasul sistemului (`clk`) folosind un mecanism robust de **Toggle Flag + Buffer**. |
| **`instr_dcd.v`** | Decodor de instrucțiuni. Interpretează pachetele primite prin SPI și generează semnale de `read`/`write` pentru regiștri. |
| **`regs.v`** | Fișierul de regiștri. Stochează configurațiile (Perioadă, Duty Cycle, Prescaler, Moduri de aliniere). |
| **`counter.v`** | Numărătorul principal cu prescaler liniar. |
| **`pwm_gen.v`** | Generatorul logic PWM. Suportă modurile *Left-Aligned*, *Right-Aligned* și *Range (Center)*. |
| **`testbench.v`** | Testbench-ul automatizat care verifică funcționalitatea sistemului. |
| **`Makefile`** | Script pentru automatizarea compilării și simulării. |

## 🛠️ Cerințe (Prerequisites)

Pentru a simula proiectul, ai nevoie de următoarele unelte open-source:

1.  **Icarus Verilog (`iverilog`)**: Compilatorul și simulatorul Verilog.
2.  **GTKWave**: Vizualizator pentru formele de undă (`.vcd`).
3.  **Make**: Pentru rularea automată a comenzilor.

### Instalare pe Linux (Ubuntu/Debian)
\`\`\`bash
sudo apt-get update
sudo apt-get install iverilog gtkwave make
\`\`\`

### Instalare pe Windows
Se recomandă instalarea [Icarus Verilog for Windows](https://bleyer.org/icarus/) (include și GTKWave). Asigură-te că adaugi executabilele în variabila de mediu \`PATH\`.

---

## 🚀 Cum se rulează (Simulare)

Proiectul include un \`Makefile\` pentru a simplifica procesul.

### 1. Compilare și Rulare Teste
Pentru a compila sursele și a rula testbench-ul automat, rulează comanda:

\`\`\`bash
make
\`\`\`
*Această comandă va compila fișierele în \`sim_top\` și va executa simularea.*

**Rezultat așteptat în consolă:**
Dacă totul funcționează corect, vei vedea rezultatele testelor marcate cu \`[PASS]\`:

\`\`\`text
--- Test 1: PWM ALIGN_LEFT, compare1=3, period=7 ---
[PASS] PWM duty aprox. corect: high=19, expected ~20

--- Test 2: PWM RANGE_BETWEEN_COMPARES, c1=2, c2=6 ---
[PASS] PWM duty aprox. corect: high=20, expected ~20

...
\`\`\`

### 2. Vizualizare Forme de Undă (Waves)
Pentru a vizualiza semnalele interne și cronogramele, rulează:

\`\`\`bash
make waves
\`\`\`
*Aceasta va deschide automat **GTKWave** și va încărca fișierul \`waves.vcd\` generat la pasul anterior.*

### 3. Curățare (Clean)
Pentru a șterge fișierele generate (executabilul și fișierul VCD):

\`\`\`bash
make clean
\`\`\`

---

## ⚙️ Detalii Tehnice

### SPI Bridge & Sincronizare (CDC)
Modulul \`spi_bridge\` utilizează o tehnică avansată de sincronizare pentru a transfera datele de la ceasul asincron \`sclk\` la ceasul sistemului \`clk\`:
* **Input Buffer:** Datele MOSI sunt salvate într-un registru tampon (\`captured_data\`) care nu se șterge la dezactivarea \`cs_n\`.
* **Toggle Flag:** Transferul complet al unui byte este semnalizat printr-un singur bit care își inversează starea (0->1, 1->0). Acest lucru elimină riscul de *Bus Skew* și pierdere a datelor la viteze mari, fiind mult mai sigur decât contoarele binare simple.

### Moduri PWM Suportate
Sistemul suportă configurarea alinierii semnalului prin regiștri:
1.  **Left Aligned:** Activ de la \`0\` până la \`Compare1\`.
2.  **Right Aligned:** Activ de la \`Compare1\` până la finalul perioadei.
3.  **Range (Between):** Activ între \`Compare1\` și \`Compare2\`.

### Hartă Regiștri (Address Map)

| Adresă | Nume Registru | Biți | Descriere |
| :--- | :--- | :--- | :--- |
| \`0x00\` | PERIOD_L | [7:0] | LSB Perioadă PWM |
| \`0x01\` | PERIOD_H | [15:8]| MSB Perioadă PWM |
| \`0x02\` | EN | [0] | Enable Counter (1=ON) |
| \`0x03\` | COMP1_L | [7:0] | LSB Prag Comparare 1 |
| \`0x04\` | COMP1_H | [15:8]| MSB Prag Comparare 1 |
| \`0x05\` | COMP2_L | [7:0] | LSB Prag Comparare 2 |
| \`0x06\` | COMP2_H | [15:8]| MSB Prag Comparare 2 |
| \`0x07\` | RESET | [0] | Counter Reset (Write Only) |
| \`0x0A\` | PRESCALE | [7:0] | Divizor frecvență (f/N+1) |
| \`0x0B\` | UP/DOWN | [0] | 0=Down, 1=Up |
| \`0x0C\` | PWM_EN | [0] | Enable PWM Output (1=ON) |
| \`0x0D\` | FUNC | [7:0] | Configurare Moduri PWM |

---

## 📝 Autori
Proiect realizat în Verilog HDL.