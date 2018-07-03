#!/usr/bin/env bats

@test "Docker should be running" {
    run docker info
    [ $status = 0 ]
}
@test "Filesystem should be ${DOCKER_FS}" {
    DOCKER_FS_CURRENT=$(docker info | grep "^Storage Driver" | cut -c17-)
    [ "$DOCKER_FS_CURRENT" = "$DOCKER_FS" ]
}
