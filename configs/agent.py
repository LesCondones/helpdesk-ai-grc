"""Stateful triage graph.

Five specialized subagents hand work off through shared state. The classifier
and summarizer fan out from START in parallel, both feed the researcher, and
the rest of the pipeline runs sequentially:

    START ─┬─> classifier ─┐
           │               ├─> researcher ─> recommender ─> synthesizer ─> END
           └─> summarizer ─┘
"""

from typing import TypedDict

from langchain_ollama import ChatOllama
from langgraph.graph import END, START, StateGraph

import tools


MODEL = "gemma4"


class TriageState(TypedDict, total=False):
    ticket_text: str
    classification: dict
    summary: dict
    kb_context: str
    recommended_actions: list[str]
    final_response: str


def _classifier_node(state: TriageState) -> dict:
    return {"classification": tools.classify(state["ticket_text"])}


def _summarizer_node(state: TriageState) -> dict:
    return {"summary": tools.summarize(state["ticket_text"])}


def _researcher_node(state: TriageState) -> dict:
    summary = state.get("summary") or {}
    query = summary.get("summary") or state["ticket_text"]
    return {"kb_context": tools.research(query)}


def _recommender_node(state: TriageState) -> dict:
    actions = tools.recommend(state["ticket_text"], state.get("kb_context", ""))
    return {"recommended_actions": actions}


SYNTHESIZER_PROMPT = """You are an IT help desk triage agent writing the final
response to the requester after a multi-stage pipeline has already done the
analysis.

You will be given:
- The original ticket
- A classification (team + urgency)
- A short summary (issue type + summary)
- Internal policy excerpts retrieved from the knowledge base
- Recommended actions from an engineer agent

Compose a clear, structured response that:
- Explicitly references the policy content from the knowledge base. Quote or
  cite it directly when relevant.
- Never claims the knowledge base had nothing relevant unless the excerpts
  are literally empty.
- States which team to contact and the urgency level.
- Lists the recommended actions in order.
- Uses clear sections (Team & Urgency, Summary, Policy Guidance, Recommended
  Actions). Keep it concise — IT staff are the audience.
- If the issue is outside the scope of the knowledge base or requires
  elevated access, explicitly state: 'This issue requires human IT staff
  intervention. Please contact your IT helpdesk directly.'
- Never fabricate policy details. If policy excerpts are insufficient,
  acknowledge the limitation clearly.
- Never take or recommend actions beyond providing guidance."""


def _synthesizer_node(state: TriageState, llm: ChatOllama) -> dict:
    classification = state.get("classification") or {}
    summary = state.get("summary") or {}
    actions = state.get("recommended_actions") or []
    kb_context = state.get("kb_context") or ""

    user_content = (
        f"Original ticket:\n{state['ticket_text']}\n\n"
        f"Classification: team={classification.get('team')}, "
        f"urgency={classification.get('urgency')}\n\n"
        f"Summary: issue_type={summary.get('issue_type')} | "
        f"{summary.get('summary')}\n\n"
        f"Knowledge base excerpts:\n{kb_context}\n\n"
        f"Recommended actions:\n- " + "\n- ".join(actions)
    )

    response = llm.invoke(
        [
            {"role": "system", "content": SYNTHESIZER_PROMPT},
            {"role": "user", "content": user_content},
        ]
    )
    return {"final_response": response.content}


def build_agent():
    """Compile and return the triage graph."""
    llm = ChatOllama(model=MODEL)

    graph = StateGraph(TriageState)
    graph.add_node("classifier", _classifier_node)
    graph.add_node("summarizer", _summarizer_node)
    graph.add_node("researcher", _researcher_node)
    graph.add_node("recommender", _recommender_node)
    graph.add_node("synthesizer", lambda state: _synthesizer_node(state, llm))

    # fan out from START
    graph.add_edge(START, "classifier")
    graph.add_edge(START, "summarizer")

    # fan in to researcher (waits for both upstream nodes)
    graph.add_edge("classifier", "researcher")
    graph.add_edge("summarizer", "researcher")

    graph.add_edge("researcher", "recommender")
    graph.add_edge("recommender", "synthesizer")
    graph.add_edge("synthesizer", END)

    return graph.compile()


def run_triage(ticket_text: str, history: list, agent=None) -> tuple[str, list]:
    """Run a single ticket through the graph and append the turn to history."""
    if agent is None:
        agent = build_agent()

    history.append({"role": "user", "content": ticket_text})
    result = agent.invoke({"ticket_text": ticket_text})
    response = result["final_response"]
    history.append({"role": "assistant", "content": response})

    return response, history


if __name__ == "__main__":
    print("IT Help Desk Triage Agent (LangGraph)")
    print("Type 'exit' to quit\n")

    agent = build_agent()
    history: list = []

    while True:
        user_input = input("You: ").strip()

        if not user_input:
            continue

        if user_input.lower() in ["exit", "quit", "bye"]:
            print("Goodbye!")
            break

        response, history = run_triage(user_input, history, agent)
        print(f"\nAgent: {response}\n")

