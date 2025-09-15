cd "$(dirname "$0")"
docker build -t vim-lsp-image .
container_id=$(docker run -d -it -v "$(pwd)/../:/app" vim-lsp-image)
docker exec -it $container_id vim -u DEFAULTS -c "source /app/plugin/lsp.vim" -c "source /app/tests/run.vim"
docker stop $container_id
docker rm $container_id
docker rmi -f vim-lsp-image
