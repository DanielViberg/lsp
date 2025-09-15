cd "$(dirname "$0")"
docker build -t vim-lsp-image .
docker run -it -v "$(pwd)/../:/app" vim-lsp-image
docker rmi -f vim-lsp-image
