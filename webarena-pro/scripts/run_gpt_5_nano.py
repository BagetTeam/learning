from agentlab.experiments.study import Study
from agentlab.agents.generic_agent import GenericAgentArgs
from agentlab.llm.llm_configs import CHAT_MODEL_ARGS_DICT
from agentlab.agents.generic_agent.agent_configs import FLAGS_GPT_4o

from webarena_pro.benchmark.benchmark import WebArenaProBenchmark
from webarena_pro.study import WebArenaProStudy

AGENT_5_NANO = GenericAgentArgs(
    chat_model_args=CHAT_MODEL_ARGS_DICT["openai/gpt-5-nano-2025-08-07"],
    flags=FLAGS_GPT_4o,
)

benchmark = WebArenaProBenchmark()  # loads src/webarena_pro/config/test.raw.json
study = WebArenaProStudy(agent_args=[AGENT_5_NANO], benchmark=benchmark, comment="webarena-pro run")
study.run(
    n_jobs=1, 
    parallel_backend="ray", 
    n_relaunch=1
    )