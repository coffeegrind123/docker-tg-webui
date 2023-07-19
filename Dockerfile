# to build and run: docker build -t docker-tg-webui:latest .; docker run -it -p 7860:7860 --name "docker-tg-webui" --rm --gpus all docker-tg-webui:latest
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND noninteractive
WORKDIR /content

RUN apt update && \
    apt install -y python3-dev python3-pip git aria2 && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/oobabooga/text-generation-webui && \
    cd /content/text-generation-webui && \
    #sed -i -e 's/cu117/cu118/g' requirements.txt && \
    python3 -m pip install -r requirements.txt

RUN echo "\
    \nhttps://huggingface.co/TheBloke/Vicuna-33B-1-3-SuperHOT-8K-GPTQ/resolve/main/vicuna-33b-1.3-superhot-8k-GPTQ-4bit--1g.act.order.safetensors \n dir=/content/text-generation-webui/models/Vicuna-33B-1-3-SuperHOT-8K-GPTQ \n out=vicuna-33b-1.3-superhot-8k-GPTQ-4bit--1g.act.order.safetensors \
    \nhttps://huggingface.co/TheBloke/Vicuna-33B-1-3-SuperHOT-8K-GPTQ/raw/main/special_tokens_map.json \n dir=/content/text-generation-webui/models/Vicuna-33B-1-3-SuperHOT-8K-GPTQ \n out=special_tokens_map.json \
    \nhttps://huggingface.co/TheBloke/Vicuna-33B-1-3-SuperHOT-8K-GPTQ/resolve/main/tokenizer.model \n dir=/content/text-generation-webui/models/Vicuna-33B-1-3-SuperHOT-8K-GPTQ \n out=tokenizer.model \
    \nhttps://huggingface.co/TheBloke/Vicuna-33B-1-3-SuperHOT-8K-GPTQ/raw/main/tokenizer_config.json \n dir=/content/text-generation-webui/models/Vicuna-33B-1-3-SuperHOT-8K-GPTQ \n out=tokenizer_config.json \
    \nhttps://huggingface.co/TheBloke/Vicuna-33B-1-3-SuperHOT-8K-GPTQ/raw/main/config.json \n dir=/content/text-generation-webui/models/Vicuna-33B-1-3-SuperHOT-8K-GPTQ \n out=config.json \
    \nhttps://huggingface.co/TheBloke/Vicuna-33B-1-3-SuperHOT-8K-GPTQ/raw/main/generation_config.json \n dir=/content/text-generation-webui/models/Vicuna-33B-1-3-SuperHOT-8K-GPTQ \n out=generation_config.json \
    \n" | aria2c --console-log-level=error -c -x 16 -s 16 -k 1M  --input-file -

CMD cd text-generation-webui && python3 server.py --listen --chat --load-in-8bit --loader exllama --max_seq_len 8192 --compress_pos_emb 4 --model /content/text-generation-webui/models/Vicuna-33B-1-3-SuperHOT-8K-GPTQ

EXPOSE 7860
