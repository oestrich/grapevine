set -e

cd apps/

cd grapevine
mix compile --force --warnings-as-errors
mix format --check-formatted
mix test
mix credo
cd assets && yarn test && cd ..
cd ..

cd data
mix compile --force --warnings-as-errors
mix test
mix credo
cd ..

cd socket
mix compile --force --warnings-as-errors
mix format --check-formatted
mix test
mix credo
cd ..

cd telnet
mix compile --force --warnings-as-errors
mix format --check-formatted
mix test
mix credo
cd ..
