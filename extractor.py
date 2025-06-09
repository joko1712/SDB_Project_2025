import os
import re
import csv

test_case_map = {
    (5, 5, 100, '256M', '8M'): (1, 'Small'),
    (10, 10, 200, '512M', '16M'): (2, 'Medium'),
    (20, 20, 500, '1G', '32M'): (3, 'Large'),
    (50, 20, 500, '2G', '64M'): (4, 'Max CPU'),
    (20, 5, 200, '256M', '8M'): (5, 'I/O Test'),
    (10, 10, 200, '2G', '64M'): (6, 'Memory'),
    (5, 20, 100, '128M', '8M'): (7, 'Latency'),
    (100, 50, 1000, '4G', '128M'): (8, 'Stress'),
    (50, 50, 500, '2G', '64M'): (41, 'Max CPU1 - Best MariaDB'),
    (50, 100, 500, '2G', '64M'): (42, 'Max CPU2 - Best MariaDB'),
    (60, 20, 500, '2G', '64M'): (43, 'Max CPU3 - Best MariaDB'),
    (100, 20, 500, '2G', '64M'): (44, 'Max CPU4 - Best MariaDB'),
    (50, 20, 500, '4G', '64M'): (45, 'Max CPU5 - Best MariaDB'),
    (50, 30, 500, '2G', '128M'): (46, 'Max CPU6 - Best MariaDB'),
    (100, 100, 1000, '4G', '128M'): (81, 'Stress1 - Best PostgreSQL'),
    (100, 150, 1000, '4G', '128M'): (82, 'Stress2 - Best PostgreSQL'),
    (150, 50, 1000, '4G', '128M'): (83, 'Stress3 - Best PostgreSQL'),
    (200, 50, 1000, '4G', '128M'): (84, 'Stress4 - Best PostgreSQL'),
    (100, 50, 1000, '8G', '128M'): (85, 'Stress5 - Best PostgreSQL'),
    (100, 50, 1000, '4G', '256M'): (86, 'Stress6 - Best PostgreSQL'),
    (10, 5, 100, '256M', '8M'): (11, 'Small1 - Virtual Users vs Warehouses'),
    (20, 5, 100, '256M', '8M'): (12, 'Small2 - Virtual Users vs Warehouses'),    
    (5, 10, 100, '256M', '8M'): (13, 'Small3 - Virtual Users vs Warehouses'),
    (5, 20, 100, '256M', '8M'): (14, 'Small4 - Virtual Users vs Warehouses'),
    }

def parse_test_case_id(filename):
    basename = os.path.splitext(filename)[0]

    maria_match = re.search(r'vu(\d+)_wh(\d+)_mc(\d+)_bp([0-9]+[MGmg])_lb([0-9]+)([MGmg]?)', basename)
    if maria_match:
        vu = int(maria_match.group(1))
        wh = int(maria_match.group(2))
        mc = int(maria_match.group(3))
        bp = maria_match.group(4).upper()
        lb = f"{maria_match.group(5)}{(maria_match.group(6) or 'M').upper()}"
        key = (vu, wh, mc, bp, lb)
        if key not in test_case_map:
            print(f"⚠️ No match for MariaDB key: {key}")
        return test_case_map.get(key, (None, None))

    pg_match = re.search(r'vu(\d+)_wh(\d+)_mc(\d+)_sb([0-9]+)([MGmg][Bb]?)_wb([0-9]+)([MGmg]?)', basename)
    if pg_match:
        vu = int(pg_match.group(1))
        wh = int(pg_match.group(2))
        mc = int(pg_match.group(3))
        sb_val = pg_match.group(4)
        sb_unit = pg_match.group(5).upper().replace('B', '')  
        bp = f"{sb_val}{sb_unit}"
        wb_val = pg_match.group(6)
        wb_unit = (pg_match.group(7) or 'M').upper()
        lb = f"{wb_val}{wb_unit}"
        key = (vu, wh, mc, bp, lb)
        if key not in test_case_map:
            print(f"⚠️ No match for PostgreSQL key: {key}")
        return test_case_map.get(key, (None, None))

    return (None, None)


def clean_dict_file(file_path):
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        if line.strip().startswith('Dictionary Settings for '):
            cleaned_lines = lines[i:]
            break
    else:
        print(f"No 'Dictionary Settings found in: {file_path}")
        return

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(cleaned_lines)

    print(f"✅ Cleaned: {file_path}")


def extract_all_logs_to_csv(folder_path):
    log_files = [f for f in os.listdir(folder_path) if f.endswith('.log')]
    summary_rows = []

    for filename in os.listdir(folder_path):
        if filename.endswith('_dict.txt'):
            clean_dict_file(os.path.join(folder_path, filename))

    for log_file in log_files:
        log_path = os.path.join(folder_path, log_file)
        csv_path = os.path.splitext(log_path)[0] + '.csv'

        tpm_values = []
        final_tpm = None
        final_nopm = None

        with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                tpm_match = re.search(r'(\d+)\s+(MariaDB|PostgreSQL) tpm', line)
                if tpm_match:
                    tpm_values.append(int(tpm_match.group(1)))

                final_match = re.search(
                    r'TEST RESULT\s*:\s*System achieved\s+(\d+)\s+NOPM\s+from\s+(\d+)\s+(MariaDB|PostgreSQL) TPM',
                    line)
                if final_match:
                    final_nopm = int(final_match.group(1))
                    final_tpm = int(final_match.group(2))

        test_id, test_name = parse_test_case_id(log_file)
        if test_id is None:
            print(f"Could not detect test case for: {log_file}")

        with open(csv_path, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['timestep', 'tpm', 'final_tpm', 'final_nopm'])
            for i, tpm in enumerate(tpm_values):
                writer.writerow([i + 1, tpm, final_tpm, final_nopm])

        summary_rows.append([
            log_file,
            test_id,
            test_name,
            final_tpm,
            final_nopm,
            len(tpm_values),
            str(tpm_values)
        ])
        print(f"Extracted {len(tpm_values)} TPM from {log_file} (Test {test_id}: {test_name})")

    summary_path = os.path.join(folder_path, "summary.csv")
    with open(summary_path, 'w', newline='') as summary_file:
        writer = csv.writer(summary_file)
        writer.writerow(['filename', 'test_id', 'test_name', 'final_tpm', 'final_nopm', 'num_timesteps', 'tpm_values'])
        writer.writerows(summary_rows)

    print(f"\nSummary written to: {summary_path}")