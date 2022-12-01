with subtest("services are up"):
    machine.wait_for_unit("docspell-restserver")
    machine.wait_for_unit("docspell-joex")
