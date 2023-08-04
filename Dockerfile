# to build and run: docker build --no-cache -t docker-tg-webui:latest .; docker run -it -p 7860:7860 -p 5001:5001 --name "docker-tg-webui" --rm --gpus all docker-tg-webui:latest
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
    python3 -m pip install sentence_transformers tiktoken SpeechRecognition num2words telegram bark

RUN git clone https://github.com/GiusTex/EdgeGPT /content/text-generation-webui/extensions/EdgeGPT && \
    git clone https://github.com/wsippel/bark_tts /content/text-generation-webui/extensions/bark_tts && \
    git clone https://github.com/innightwolfsleep/text-generation-webui-telegram_bot /content/text-generation-webui/extensions/telegram_bot && \
    for i in text-generation-webui/extensions/*/requirements.txt ; do python3 -m pip install -r $i ; done

RUN echo $TELEGRAM_TOKEN > /content/text-generation-webui/extensions/telegram_bot/configs/telegram_token.txt

# fix to disable conda check in edgegpt
RUN sed -i '/# Get current acheong08 EdgeGPT version installed/,/print("Version not found.")/ s/^/#/' /content/text-generation-webui/extensions/EdgeGPT/script.py

# enable cookies for edgegpt by default
RUN sed -i 's/UseCookies=False/UseCookies=True/g' /content/text-generation-webui/extensions/EdgeGPT/script.py

# echo _U cookie for enabling bing chat
RUN echo '[{"domain":".bing.com","expirationDate":1692338488.751139,"hostOnly":false,"httpOnly":false,"name":"_U","path":"/","sameSite":"no_restriction","secure":true,"session":false,"storeId":null,"value":"asdasdasdasdasdasdasdasdasdasdasd"}]' > /content/text-generation-webui/extensions/EdgeGPT/cookies.json

RUN echo "\
    \nhttps://huggingface.co/TheBloke/llama2_7b_chat_uncensored-GPTQ/resolve/main/gptq_model-4bit-128g.safetensors \n dir=/content/text-generation-webui/models/llama2_7b_chat_uncensored-GPTQ \n out=gptq_model-4bit-128g.safetensors \
    \nhttps://huggingface.co/TheBloke/llama2_7b_chat_uncensored-GPTQ/raw/main/special_tokens_map.json \n dir=/content/text-generation-webui/models/llama2_7b_chat_uncensored-GPTQ \n out=special_tokens_map.json \
    \nhttps://huggingface.co/TheBloke/llama2_7b_chat_uncensored-GPTQ/resolve/main/tokenizer.model \n dir=/content/text-generation-webui/models/llama2_7b_chat_uncensored-GPTQ \n out=tokenizer.model \
    \nhttps://huggingface.co/TheBloke/llama2_7b_chat_uncensored-GPTQ/raw/main/tokenizer_config.json \n dir=/content/text-generation-webui/models/llama2_7b_chat_uncensored-GPTQ \n out=tokenizer_config.json \
    \nhttps://huggingface.co/TheBloke/llama2_7b_chat_uncensored-GPTQ/raw/main/config.json \n dir=/content/text-generation-webui/models/llama2_7b_chat_uncensored-GPTQ \n out=config.json \
    \nhttps://huggingface.co/TheBloke/llama2_7b_chat_uncensored-GPTQ/raw/main/generation_config.json \n dir=/content/text-generation-webui/models/llama2_7b_chat_uncensored-GPTQ \n out=generation_config.json \
    \n" | aria2c --console-log-level=error -c -x 16 -s 16 -k 1M  --input-file -

# uncomment if you want to use local files
#COPY gptq_model-4bit-128g.safetensors /content/text-generation-webui/models/llama2_7b_chat_uncensored-GPTQ
#COPY text_2.pt /root/.cache/suno/bark_v0/
#COPY fine_2.pt /root/.cache/suno/bark_v0/
#COPY coarse_2.pt /root/.cache/suno/bark_v0/

CMD cd text-generation-webui && python server.py --listen --chat --extensions openai bark_tts sd_api_pictures send_pictures whisper_stt EdgeGPT --load-in-4bit --loader exllama --model /content/text-generation-webui/models/llama2_7b_chat_uncensored-GPTQ

# disabled: telegram_bot

EXPOSE 7860 5001
