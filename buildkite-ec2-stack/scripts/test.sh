#!/usr/bin/env bats

# docker
@test "Check docker is running" {
	run docker info
	[ $status = 0 ]
}

@test "Creating files in a docker container are owned by buildkite-agent" {
  run docker run -v "$PWD:/pwd" --rm -it alpine:latest mkdir /pwd/llamas
 	[ $status = 0 ]
  stat llamas
  stat llamas | grep 'Uid: ( 2000/buildkite-agent)   Gid: ( 1001/  docker)'
}

@test "Containers can access docker socket" {
  run docker run --rm -v /var/run/docker.sock:/var/run/docker.sock docker:latest version
 	[ $status = 0 ]
}

# buildkite-agent
@test "Check buildkite-agent-1 is running" {
	run systemctl is-active --quiet "buildkite-agent@1"
	[ $status = 0 ]
}

@test "Check lifecycled is running" {
	run systemctl is-active --quiet "lifecycled"
	[ $status = 0 ]
}

# cron
@test "Check low disk docker cron script can run" {
	run /etc/cron.hourly/docker-low-disk-gc
  echo "status = ${status}"
  echo "output = ${output}"
	[ $status = 0 ]
}

@test "Check docker cron script can run" {
	run /etc/cron.hourly/docker-gc
  echo "status = ${status}"
  echo "output = ${output}"
	[ $status = 0 ]
}
