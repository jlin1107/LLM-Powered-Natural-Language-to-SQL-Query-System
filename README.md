
For our project we used the Phi-4-mini-instruct LLM. 

Once you have all the packages installed to run the base project, just type python database_llm.py in the command line.
Also, for our project we assume the ilab_script.py will just be in the home directory on ilab, so it can run, if not just change the
path of the ilab_script.py in database_llm.py, same with the python path. We assume that you will also just call python3 to run the script as well, 
since we wouldn't know what virtual environment directory to point it towards etc. We also assume the model .gguf file will be in the same directory as all the scripts as well.

For the extra credit run: streamlit run app.py, just make sure you are running it from inside the Python_Scripts folder.

Team Member Names:

Ian Quaye - inq1
John Lin - jl3209
Joffre Loor - jal632
Joseph Shabaan - jss502

Contributions:

Ian Quaye and John Lin both worked on steps 1-4 for LOCALLY in the assignment document. Meaning they made the SQL subet script, 
the running LLM, the basic text processing, and provided the loop for taking questions from the user.

Joseph Shabaan and Joffre Loor both worked on the ilab_script.py, processing the response to only extract the SQL query, creating the code to make a 
SSH tunnel to call the script on ilab using the LLM output and connected the project together. We also had extra time to spare, so we decided
to create the frontend for the extra credit as well, attempting to cover all 3 points for it. 

What we found challenging:

We found the process of altering the system prompt of the LLM to properly generate good SQL statements to be fairly challenging. Since this is not a state of the art model, 
and is simply just run locally, it was a bit tedious to get it to properly run on all the testing commands. It was also initially troublesome to figure out how to SSH,
and how the initial pipeline was going to work and connect with everything. 

What we found interesting:

We found the whole project interesting, as it was not something we particularly have done or dealt with before. We have all had experience with LLMs, but we felt
that this was an interesting pipeline to stitch together, and liked the idea of creating the system where the LLM creates the SQL query based on the user prompt.


Extra Credit:

Yes, we did do the extra credit. In order to run it, you must install all our requirements.txt in a python virtual environment or just normal python.
We have already included in the Python_Scripts folder the subset database so you do not need to worry about the path as long as you call the script
from that folder, just make sure the microsoft_Phi-4-mini-instruct.gguf file is present as well in the Python_Scripts folder. Once you have the ilab script and everything setup, you can use the command: streamlit run app.py, to run it in the CLI. Then it will
open the frontend on your browser.

We implemented all features required, such as interactive tables, we also included a frontend credential interface for ilab SSH, a textbox so you can submit your prompt, a loading spinner telling you that your prompt is being processed. The raw SQL extracted, and the post processed SQL from the LLM, and the original user query made to the LLM. Then once it's processed the user has the ability to go back and ask a new question. The table output is also in its own separate box, as required. We also allowed for an option to download the output as a csv. This is all done from a modern sleek dark mode style interface. 