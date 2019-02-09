set -e

mix test
mix credo
cd assets && yarn test && cd ..
