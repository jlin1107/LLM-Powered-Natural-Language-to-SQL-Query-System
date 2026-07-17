#!/usr/bin/env python3
"""
database_llm.py

Local natural-language-to-SQL program for Project 2.

This version uses llama-cpp-python directly, so it runs the local GGUF model
inside this Python program instead of starting llama-server.

What this does:
1. Loads a local GGUF model with llama_cpp.Llama.
2. Reads your schema subset SQL file.
3. Prompts the local LLM to produce one PostgreSQL SELECT query.
4. Extracts and safety-checks the SELECT query.
5. SSHes into ILAB and runs ilab_script.py with that query.
6. Prints the database result.

Before running:
- Put the GGUF model in ./models/
- Put normalized_hmda_subset.sql next to this script
- Put ilab_script.py on ILAB at REMOTE_SCRIPT below, or edit the constant
- Install requirements: pip install -r requirements.txt

Run:
    python database_llm.py

Exit:
    type exactly: exit
"""

from __future__ import annotations

import getpass
import re
import shlex
import sys
from pathlib import Path

import paramiko
from llama_cpp import Llama

# =========================
# EDIT THESE DEFAULTS ONLY IF NEEDED
# =========================

MODEL_PATH = Path("microsoft_Phi-4-mini-instruct-Q4_K_M.gguf")
SCHEMA_PATH = Path("Database_Subset.sql")

CTX_SIZE = 2048
MAX_TOKENS = 200
TEMPERATURE = 0.1
N_GPU_LAYERS = 0  # 0 = CPU only. Increase only if your llama-cpp-python install supports GPU.

DEFAULT_ILAB_HOST = "ilab1.cs.rutgers.edu"
REMOTE_PYTHON = "python3"
REMOTE_SCRIPT = "~/ilab_script.py"

SYSTEM_PROMPT = """You are an expert PostgreSQL assistant that generates correct SQL SELECT queries.

Rules:

1. Output EXACTLY one SQL SELECT query.
   - Do NOT include explanations, markdown, or code fences.

2. Use ONLY the tables and columns provided in the schema.

3. Table usage:
   - ALWAYS alias every table (e.g., Application a, DenialReason dr).
   - ALWAYS qualify EVERY column with its table alias (e.g., a.loan_amount_000s, dr.denial_reason_name).
   - NEVER use unqualified column names.

4. Joins:
   - Use proper JOIN conditions based on matching keys.
   - Always join lookup tables when needed for readable output.

5. Readability:
   - Prefer descriptive columns over codes.
     Example: use dr.denial_reason_name instead of dr.denial_reason_code.

6. Aggregations:
   - For "most common", "highest", "lowest":
     - Use COUNT(), GROUP BY, ORDER BY DESC, LIMIT 1.

   - CRITICAL RULE:
     Every column in SELECT that is NOT inside an aggregate function
     MUST appear EXACTLY in GROUP BY.

   - If SELECT includes dr.denial_reason_name,
     then GROUP BY MUST use dr.denial_reason_name.

   - NEVER group by a different column than what appears in SELECT.

   - Example (CORRECT):
     SELECT dr.denial_reason_name, COUNT(*)
     ...
     GROUP BY dr.denial_reason_name

   - Example (WRONG):
     SELECT dr.denial_reason_name, COUNT(*)
     ...
     GROUP BY ard.denial_reason_code

7. Safety:
   - ONLY generate SELECT queries.
   - NEVER use INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE.

8. Simplicity:
   - Prefer simple, clean, readable SQL.
   - Avoid unnecessary joins or columns.

Schema:
"""


# =========================
# FILE SETUP
# =========================

def require_file(path: Path, description: str) -> Path:
    resolved = path.expanduser().resolve()
    if not resolved.exists():
        raise FileNotFoundError(f"{description} not found: {resolved}")
    if not resolved.is_file():
        raise ValueError(f"{description} is not a file: {resolved}")
    return resolved


def load_schema() -> str:
    schema_path = require_file(SCHEMA_PATH, "Schema file")
    return schema_path.read_text(encoding="utf-8")


def load_llm() -> Llama:
    model_path = require_file(MODEL_PATH, "Model file")
    print(f"Loading local model: {model_path}")
    print("This may take a little while on the first load.\n")

    return Llama(
        model_path=str(model_path),
        n_ctx=CTX_SIZE,
        n_gpu_layers=N_GPU_LAYERS,
        verbose=False,
    )


# =========================
# LLM + SQL PROCESSING
# =========================

def build_prompt(schema_text: str, question: str) -> str:
    return f"""{SYSTEM_PROMPT}

Write a PostgreSQL SELECT query for the user's question.

SCHEMA:
{schema_text}

QUESTION:
{question}

SQL:"""


def ask_llm(llm: Llama, schema_text: str, question: str) -> str:
    prompt = build_prompt(schema_text, question)

    # create_completion is the most portable llama-cpp-python API.
    response = llm.create_completion(
        prompt=prompt,
        max_tokens=MAX_TOKENS,
        temperature=TEMPERATURE,
        stop=["\n\n", "```", "Question:", "SCHEMA:"],
    )

    return response["choices"][0]["text"].strip()


def extract_select_query(llm_output: str) -> str:
    text = llm_output.strip()

    # Remove ```sql ... ``` if the model ignores instructions.
    fenced = re.search(r"```(?:sql)?\s*(.*?)```", text, flags=re.IGNORECASE | re.DOTALL)
    if fenced:
        text = fenced.group(1).strip()

    # Extract first SELECT/WITH query.
    match = re.search(r"\b(SELECT|WITH)\b.*", text, flags=re.IGNORECASE | re.DOTALL)
    if not match:
        raise ValueError(f"Could not find a SELECT query in LLM output:\n{text}")

    query = match.group(0).strip()
    if ";" in query:
        query = query[: query.index(";") + 1]
    else:
        query += ";"

    lowered = query.lower().strip()
    forbidden_words = [
        "insert", "update", "delete", "drop", "alter", "create",
        "truncate", "grant", "revoke", "copy", "merge",
    ]

    if not (lowered.startswith("select") or lowered.startswith("with")):
        raise ValueError(f"Only SELECT/WITH queries are allowed. Got:\n{query}")

    if any(re.search(rf"\b{word}\b", lowered) for word in forbidden_words):
        raise ValueError(f"Unsafe SQL keyword found. Refusing to run:\n{query}")

    return query


# =========================
# SSH EXECUTION
# =========================

def get_ssh_info() -> tuple[str, str, str]:
    print("ILAB login info")
    host = input(f"Host [{DEFAULT_ILAB_HOST}]: ").strip() or DEFAULT_ILAB_HOST
    username = input("Username: ").strip()
    while not username:
        username = input("Username required: ").strip()
    password = getpass.getpass("Password (hidden): ")
    return host, username, password


def run_query_on_ilab(sql_query: str, host: str, username: str, password: str) -> str:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        client.connect(
            hostname=host,
            username=username,
            password=password,
            look_for_keys=False,
            allow_agent=False,
            timeout=15,
            banner_timeout=15,
            auth_timeout=15,
        )

        start_marker = "__QUERY_OUTPUT_START__"
        end_marker = "__QUERY_OUTPUT_END__"

        remote_command = (
            f'echo {start_marker}; '
            f'{REMOTE_PYTHON} {REMOTE_SCRIPT} {shlex.quote(sql_query)}; '
            f'echo {end_marker}'
        )

        command = f"bash -lc {shlex.quote(remote_command)}"

        _stdin, stdout, stderr = client.exec_command(command)

        output = stdout.read().decode("utf-8", errors="replace")
        error = stderr.read().decode("utf-8", errors="replace")
        status = stdout.channel.recv_exit_status()

        if status != 0:
            raise RuntimeError(f"Remote command failed:\n{error}")

        if start_marker in output and end_marker in output:
            output = output.split(start_marker, 1)[1]
            output = output.split(end_marker, 1)[0]

        return output.strip()

    finally:
        client.close()


# =========================
# MAIN LOOP
# =========================

def main() -> None:
    schema_text = load_schema()
    llm = load_llm()
    host, username, password = get_ssh_info()

    print("\nAsk questions about the database. Type exactly 'exit' to quit.\n")
    while True:
        question = input("Question> ").strip()
        if question == "exit":
            print("Exiting.")
            return
        if not question:
            continue

        try:
            llm_output = ask_llm(llm, schema_text, question)
            sql_query = extract_select_query(llm_output)

            print("\nLLM output:")
            print(llm_output)
            print("\nExtracted SQL:")
            print(sql_query)

            print("\nQuery result:")
            result = run_query_on_ilab(sql_query, host, username, password)
            print(result)
            print()
        except Exception as exc:
            print(f"\nError: {exc}\n", file=sys.stderr)


_cached_schema = None
_cached_llm = None
_cached_login = None


def run_pipeline_with_login(question: str, host: str, username: str, password: str):
    """
    Streamlit-friendly cached pipeline.

    Caches:
    - schema
    - loaded LLM model
    - login info for this app startup

    Does NOT cache:
    - user questions
    - LLM outputs
    - SQL queries
    - database results
    """

    global _cached_schema, _cached_llm, _cached_login

    if _cached_schema is None:
        _cached_schema = load_schema()

    if _cached_llm is None:
        _cached_llm = load_llm()

    if _cached_login is None:
        _cached_login = {
            "host": host,
            "username": username,
            "password": password
        }

    cached_host = _cached_login["host"]
    cached_username = _cached_login["username"]
    cached_password = _cached_login["password"]

    llm_output = ask_llm(_cached_llm, _cached_schema, question)
    sql_query = extract_select_query(llm_output)

    result_text = run_query_on_ilab(
        sql_query=sql_query,
        host=cached_host,
        username=cached_username,
        password=cached_password
    )

    return llm_output, sql_query, result_text
    
if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nExiting.")

