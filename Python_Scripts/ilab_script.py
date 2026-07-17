import sys
import psycopg2


def get_query():
    if len(sys.argv) > 1:
        return " ".join(sys.argv[1:]).strip()

    query = sys.stdin.read().strip()
    if not query:
        print("Error: No SQL query provided.")
        sys.exit(1)

    return query


def validate_query(query):
    cleaned = query.strip().lower()

    if not cleaned.startswith("select"):
        print("Error: Only SELECT queries are allowed.")
        sys.exit(1)

    forbidden_words = ["insert", "update", "delete", "drop", "alter", "create", "truncate"]

    for word in forbidden_words:
        if word in cleaned:
            print(f"Error: Forbidden SQL keyword detected: {word}")
            sys.exit(1)


def main():
    query = get_query()
    validate_query(query)

    try:
        conn = psycopg2.connect(
            host="postgres.cs.rutgers.edu"
        )

        cur = conn.cursor()
        cur.execute(query)

        rows = cur.fetchall()
        colnames = [desc[0] for desc in cur.description]

        # Output as CSV manually
        print(",".join(colnames))

        for row in rows:
            print(",".join(str(x) if x is not None else "" for x in row))

        cur.close()
        conn.close()

    except Exception as e:
        print("Database error:", e)
        sys.exit(1)


if __name__ == "__main__":
    main()