import os
from flask import Flask, request, render_template
from azure.identity import ManagedIdentityCredential
from azure.storage.blob import BlobServiceClient

STORAGE_ACCOUNT_NAME = os.getenv("STORAGE_ACCOUNT_NAME", "stademoupload")
CONTAINER_NAME = os.getenv("CONTAINER_NAME", "uploads")
BLOB_SERVICE_URL = f"https://{STORAGE_ACCOUNT_NAME}.blob.core.windows.net"

# Managed Identity Auth
credential = ManagedIdentityCredential()
blob_service_client = BlobServiceClient(account_url=BLOB_SERVICE_URL, credential=credential)

app = Flask(__name__)

# Upload Route
@app.route("/", methods=["GET", "POST"])
def upload_file():
    if request.method == "POST":
        if "file" not in request.files:
            return "Nenhum arquivo selecionado!", 400

        file = request.files["file"]
        if file.filename == "":
            return "Nome do arquivo inválido!", 400

        try:
            # Upload to Blob Storage
            blob_client = blob_service_client.get_blob_client(
                container=CONTAINER_NAME, blob=file.filename
            )
            blob_client.upload_blob(file.stream, overwrite=True)

            return f"Arquivo '{file.filename}' enviado com sucesso!", 200
        except Exception as e:
            return f"Erro ao enviar arquivo: {str(e)}", 500

    return render_template("index.html")


if __name__ == "__main__":
    app.run(debug=True)
