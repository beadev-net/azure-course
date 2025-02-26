import os
import logging
from flask import Flask, request, render_template
from azure.identity import ManagedIdentityCredential
from azure.core.pipeline.transport import RequestsTransport
from azure.storage.blob import BlobServiceClient
from opencensus.ext.azure.log_exporter import AzureLogHandler


STORAGE_ACCOUNT_NAME = os.getenv("STORAGE_ACCOUNT_NAME", "stademoupload")
CONTAINER_NAME = os.getenv("CONTAINER_NAME", "uploads")
BLOB_SERVICE_URL = f"https://{STORAGE_ACCOUNT_NAME}.blob.core.windows.net"

# Managed Identity Auth
credential = ManagedIdentityCredential()
transport = RequestsTransport(connection_verify=False)
blob_service_client = BlobServiceClient(account_url=BLOB_SERVICE_URL, credential=credential, transport=transport)

app = Flask(__name__)

# Application Insights Configuration
APPINSIGHTS_CONNECTION_STRING = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
if not APPINSIGHTS_CONNECTION_STRING:
    print("⚠️ APPLICATIONINSIGHTS_CONNECTION_STRING is not set!")
else:
    # Logging setup
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    logger.addHandler(AzureLogHandler(connection_string=APPINSIGHTS_CONNECTION_STRING))

# Upload Route
@app.route("/", methods=["GET", "POST"])
def upload_file():
    if request.method == "POST":
        if "file" not in request.files:
            message = "Nenhum arquivo selecionado!"
            logger.warning(message)
            return message, 400

        file = request.files["file"]
        if file.filename == "":
            message = "Nome do arquivo inválido!"
            logger.warning(message)
            return message, 400

        try:
            # Upload to Blob Storage
            blob_client = blob_service_client.get_blob_client(
                container=CONTAINER_NAME, blob=file.filename
            )
            blob_client.upload_blob(file.stream, overwrite=True)
            message = f"Arquivo '{file.filename}' enviado com sucesso!"
            logger.info(message)

            return message, 200
        except Exception as e:
            message = f"Erro ao enviar arquivo: {str(e)}"
            logger.error(message)
            return message, 500

    logger.info("Página inicial carregada!")
    return render_template("index.html")


if __name__ == "__main__":
    app.run(debug=True)
