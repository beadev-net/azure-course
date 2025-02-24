# Usa uma imagem base do Python
FROM python:3.9

# Define diretório de trabalho no container
WORKDIR /app

# Copia os arquivos necessários
COPY requirements.txt .
COPY main.py .
COPY templates ./templates

# Instala as dependências
RUN pip install --no-cache-dir -r requirements.txt

# Expõe a porta 80
EXPOSE 80

# Comando de inicialização do Flask usando Gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:80", "main:app"]
