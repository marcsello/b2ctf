import lupa
import vdf
import sys


def read_sh_config(sh_config_path:str) -> list[tuple]:

    lua = lupa.LuaRuntime(unpack_returned_tuples=True)

    lua.globals()["FCVAR_REPLICATED"] = 1
    lua.globals()["FCVAR_NOT_CONNECTED"] = 2

    convars = []

    def record(name, value, flags, helptext):
        convars.append((name, value, helptext)) # TODO: record type somehow
        return {
            "GetString": lambda _: str(value),
            "GetBool": lambda _: value in ["1", 1],
            "GetInt": lambda _: int(value),
            "GetFloat": lambda _: float(value),
        }

    lua.globals()["CreateConVar"] = record

    with open(sh_config_path, "r") as f:
        lua.execute(f.read())

    return convars

def read_gamemode_config(config_path:str) -> list[tuple]:
    with open(config_path, "r") as f:
        d = vdf.load(f)
    
    convars = []
    keys = set()
    for k, v in d["b2ctf"]["settings"].items():
        convars.append((v['name'], v['default'], v['text']))
        keys.add(int(k))

    assert len(keys) == len(convars) # this will fail, if I mess up the indexes in the config file

    return convars

def find_convar(convar_list:list, name:str) -> tuple | None:
    for convar in convar_list:
        if convar[0] == name:
            return convar
    return None

SUCCESS = True
def error(msg:str):
    global SUCCESS
    print("ERROR:", msg)
    SUCCESS = False
    

def compare_convar_lists_one_way(list_a:list, list_b:list):
    for a_name, a_value, a_text in list_a:
        b_convar = find_convar(list_b, a_name)
        if not b_convar:
            error(f"No matching convar for {a_name}")
            continue

        b_value = b_convar[1]
        if a_value != b_value:
            error(f"Mismatching default value for {a_name} ('{b_value}' != '{b_value}')")

        b_text = b_convar[2]
        if a_text != b_text:
            error(f"Mismatching help text for {a_name} ('{a_text}' != '{b_text}')")

def compare_convars(convars_in_lua:list, convars_in_config:list) -> bool:
    if not len(convars_in_lua) == len(convars_in_config):
        error("The number of defined convars are not equal!")

    compare_convar_lists_one_way(convars_in_lua, convars_in_config)
    compare_convar_lists_one_way(convars_in_config, convars_in_lua)


def main():
    print("executing sh_config.lua...")
    convars_in_lua = read_sh_config("gamemode/sh_config.lua")

    print("reading gamemode config...")
    convars_in_config = read_gamemode_config("b2ctf.txt")
    
    print("comparing convars...")
    compare_convars(convars_in_lua, convars_in_config)

    if SUCCESS:
        print("SUCCESS: The defined convars are identical.")
    else:
        print("FAIL: The defined convars are not identical.")
        sys.exit(1) # fail the build


if __name__ == "__main__":
    main()
