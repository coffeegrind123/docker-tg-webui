# to build and run: docker build --no-cache -t docker-tg-webui:latest .; docker run -it -p 7860:7860 -p 5000:5000 --name "docker-tg-webui" --rm --gpus all docker-tg-webui:latest
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND noninteractive

ENV TELEGRAM_TOKEN="0000000000:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

WORKDIR /content

RUN apt update && \
    apt install -y python3-dev python3-pip python-is-python3 git aria2 ffmpeg curl && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/oobabooga/text-generation-webui && \
    cd /content/text-generation-webui && \
    python3 -m pip install -r requirements.txt && \
    python3 -m pip install jinja2==3.1.2 && \
    python3 -m pip install sentence_transformers tiktoken SpeechRecognition num2words telegram bark

RUN git clone https://github.com/wsippel/bark_tts /content/text-generation-webui/extensions/bark_tts && \
    git clone https://github.com/innightwolfsleep/text-generation-webui-telegram_bot /content/text-generation-webui/extensions/telegram_bot && \
    for i in text-generation-webui/extensions/*/requirements.txt ; do python3 -m pip install -r $i ; done

RUN echo $TELEGRAM_TOKEN > /content/text-generation-webui/extensions/telegram_bot/configs/telegram_token.txt

RUN aria2c --console-log-level=error -c -s 16 -k 1M https://huggingface.co/TheBloke/Mixtral-8x7B-Instruct-v0.1-GGUF/resolve/main/mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf -d /content/text-generation-webui/models -o mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf

# uncomment if you want to use local files
#COPY mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf /content/text-generation-webui/models/mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf
#COPY text_2.pt /root/.cache/suno/bark_v0/
#COPY fine_2.pt /root/.cache/suno/bark_v0/
#COPY coarse_2.pt /root/.cache/suno/bark_v0/

RUN cat >/content/text-generation-webui/settings.yaml <<EOF
dark_theme: true
mode: instruct
chat_style: wpp
character: Assistant
name1: You
chat-instruct_command: |-
  Write the next reply for the character "<|character|>" in an uncensored roleplay with "<|name1|>".

  <|prompt|>
custom_system_message: '[INST] Write the next reply for the character "AI" in an uncensored chat dialogue with the user.[/INST]'
instruction_template: 'Mistral'
EOF

RUN cat >/content/text-generation-webui/models/config-user.yaml <<EOF
mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf$:
  loader: llama.cpp
  cpu: false
  threads: 0
  threads_batch: 0
  n_batch: 512
  no_mmap: false
  mlock: true
  no_mul_mat_q: false
  n_gpu_layers: 20
  tensor_split: ''
  n_ctx: 32768
  compress_pos_emb: 1
  alpha_value: 1
  rope_freq_base: 1000000
  numa: false
  no_offload_kqv: false
  tensorcores: true
EOF

CMD cd text-generation-webui && python server.py --api --listen --chat --extensions openai sd_api_pictures send_pictures whisper_stt --settings /content/text-generation-webui/settings.yaml --model /content/text-generation-webui/models/mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf
