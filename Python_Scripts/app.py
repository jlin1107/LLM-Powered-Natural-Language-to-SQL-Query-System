import streamlit as st
import pandas as pd
from io import StringIO

from database_llm import run_pipeline_with_login


def result_text_to_dataframe(result_text: str):
    try:
        return pd.read_csv(StringIO(result_text))
    except Exception:
        return None


st.set_page_config(
    page_title="Database LLM Query App",
    page_icon="🗄️",
    layout="wide"
)

if "latest_result" not in st.session_state:
    st.session_state.latest_result = None


st.title("Database Natural Language Query")
st.caption("Ask questions in plain English and view SQL, LLM output, and database results.")

with st.sidebar:
    st.header("ILAB Login")

    ilab_host = st.text_input("ILAB Host", value="ilab1.cs.rutgers.edu")
    ilab_username = st.text_input("ILAB Username", placeholder="Example: jal632")
    ilab_password = st.text_input("ILAB Password", type="password")

    st.caption("Password is hidden and used only for SSH into ILAB.")


st.markdown("### Ask a Question")

with st.form("query_form", clear_on_submit=True):
    question = st.text_input(
        "Enter your natural language database question:",
        placeholder="Example: How many mortgages have a loan value greater than applicant income?"
    )

    submitted = st.form_submit_button("Submit Query")


if submitted:
    if not question.strip():
        st.warning("Please enter a question first.")

    elif not ilab_username.strip() or not ilab_password:
        st.warning("Please enter your ILAB username and password in the sidebar.")

    else:
        st.session_state.latest_result = None

        with st.spinner("Running LLM inference and querying database..."):
            try:
                llm_output, sql_query, result_text = run_pipeline_with_login(
                    question=question,
                    host=ilab_host,
                    username=ilab_username,
                    password=ilab_password
                )

                result_df = result_text_to_dataframe(result_text)

                st.session_state.latest_result = {
                    "question": question,
                    "llm_output": llm_output,
                    "sql_query": sql_query,
                    "result_text": result_text,
                    "result_df": result_df,
                }

            except Exception as e:
                st.error(f"Error: {e}")


if st.session_state.latest_result:
    result = st.session_state.latest_result

    st.divider()
    st.markdown("## Output")

    st.markdown("### Original User Question")
    st.info(result["question"])

    st.markdown("### Raw LLM Output")
    st.code(result["llm_output"], language="text")

    st.markdown("### Extracted SQL Query")
    st.code(result["sql_query"], language="sql")

    st.markdown("### Database Output")

    result_df = result["result_df"]

    if result_df is not None and not result_df.empty:
        col1, col2, col3 = st.columns(3)

        with col1:
            st.metric("Rows Returned", len(result_df))

        with col2:
            st.metric("Columns Returned", len(result_df.columns))

        with col3:
            st.metric("Query Status", "Success")

        st.dataframe(
            result_df,
            width="stretch",
            hide_index=True
        )

        csv = result_df.to_csv(index=False).encode("utf-8")

        st.download_button(
            label="Download Results as CSV",
            data=csv,
            file_name="query_results.csv",
            mime="text/csv"
        )

    else:
        st.warning("Query ran but returned no data.")

else:
    st.success("Enter a question above to begin.")