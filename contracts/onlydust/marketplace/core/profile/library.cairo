%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.token.erc721.library import ERC721

from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.security.safemath.library import SafeUint256

//
// Enums
//
struct Role {
    // Keep ADMIN role first of this list as 0 is the default admin value to manage roles in AccessControl library
    ADMIN: felt,  // ADMIN role, can assign/revoke roles
    MINTER: felt,  // MINTER role, can mint a token
}

//
// Structs
//
struct Token {
    exists: felt,
    tokenId: Uint256,
}

//
// Storage
//
@storage_var
func total_supply_() -> (total_supply: Uint256) {
}

@storage_var
func tokens_(owner: felt) -> (token: Token) {
}

@storage_var
func metadata_contracts_(label: felt) -> (metadata_contract: felt) {
}

namespace profile {
    // Initialize the profile name and symbol
    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(admin: felt) {
        ERC721.initializer('Death Note Profile', 'DNP');
        AccessControl.initializer();
        AccessControl._grant_role(Role.ADMIN, admin);
        return ();
    }

    // Grant the ADMIN role to a given address
    func grant_admin_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        AccessControl.grant_role(Role.ADMIN, address);
        return ();
    }

    // Revoke the ADMIN role from a given address
    func revoke_admin_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        with_attr error_message("profile: Cannot self renounce to ADMIN role") {
            internal.assert_not_caller(address);
        }
        AccessControl.revoke_role(Role.ADMIN, address);
        return ();
    }

    // Grant the MINTER role to a given address
    func grant_minter_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        AccessControl.grant_role(Role.MINTER, address);
        return ();
    }

    // Revoke the MINTER role from a given address
    func revoke_minter_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        AccessControl.revoke_role(Role.MINTER, address);
        return ();
    }

    // Get the profile name
    func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
        return ERC721.name();
    }

    // Get the profile symbol
    func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        symbol: felt
    ) {
        return ERC721.symbol();
    }

    // Mint a new token
    func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(to: felt) -> (
        tokenId: Uint256
    ) {
        alloc_locals;

        internal.assert_only_minter();

        let (token) = tokens_.read(to);
        if (token.exists != 0) {
            return (token.tokenId,);
        }

        let (tokenId) = internal.mint(to);
        tokens_.write(to, Token(1, tokenId));

        return (tokenId,);
    }

    // Get the owner of a tokenId
    func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
    ) -> (owner: felt) {
        return ERC721.owner_of(tokenId);
    }
}

namespace internal {
    func assert_not_caller{syscall_ptr: felt*}(address: felt) {
        let (caller_address) = get_caller_address();
        assert_not_zero(caller_address - address);
        return ();
    }

    func assert_only_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        with_attr error_message("profile: ADMIN role required") {
            AccessControl.assert_only_role(Role.ADMIN);
        }

        return ();
    }

    func assert_only_minter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        with_attr error_message("profile: MINTER role required") {
            AccessControl.assert_only_role(Role.MINTER);
        }

        return ();
    }

    func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(to: felt) -> (
        tokenId: Uint256
    ) {
        alloc_locals;

        let (local tokenId: Uint256) = total_supply_.read();
        ERC721._mint(to, tokenId);

        let (new_supply) = SafeUint256.add(tokenId, Uint256(1, 0));
        total_supply_.write(new_supply);

        return (tokenId,);
    }
}
