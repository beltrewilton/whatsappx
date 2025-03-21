use base64::prelude::*;
use rsa::pkcs8::DecodePrivateKey;
use rsa::{RsaPrivateKey, Oaep, sha2::Sha256};
use rustler::types::binary::{Binary, OwnedBinary};
use rustler::{Atom, Encoder, Env, Term};
use rustler::{Resource, ResourceArc};

// declare some atoms that we use in the package
mod atoms {
    rustler::atoms! {
        ok,
        error,
        decoding,
        not_found,
        io_error,
    }
}

// merging errors from different packages together
pub enum Error {
    PKCS8Err(rsa::pkcs8::Error),
    DecodeError(base64::DecodeError),
    RsaErr(rsa::Error),
    AllocErr
}

// errors from the rsa::pkcs8 package
impl From<rsa::pkcs8::Error> for Error {
    fn from(e: rsa::pkcs8::Error) -> Error {
        return Error::PKCS8Err(e)
    }
}

// errors from the base64 package
impl From<base64::DecodeError> for Error {
    fn from(e: base64::DecodeError) -> Error {
        return Error::DecodeError(e)
    }
}

// errors from the rsa package
impl From<rsa::Error> for Error {
    fn from(e: rsa::Error) -> Error {
        return Error::RsaErr(e)
    }
}

// convert the error to atom
fn error_to_term(err: &Error) -> Atom {
    match err {
        Error::PKCS8Err(e) => {
            println!("PKCS8 error: {:?}", e);
            atoms::decoding()
        },
        Error::DecodeError(_) => atoms::decoding(),
        Error::RsaErr(_) => atoms::decoding(),
        Error::AllocErr => atoms::decoding(),
    }
}

// return an own resource type
struct MyRsaPrivateKey(RsaPrivateKey);

// is this need for the registration
#[rustler::resource_impl]
impl Resource for MyRsaPrivateKey {

}

/// This function fetches the private key from the pem string. The password is optional.
///
#[rustler::nif(schedule = "DirtyCpu")]
fn fetch_private_key(env: Env, private_key_pem: String, password: Option<String>) -> Result<Term, rustler::Error> {
    match crate::do_fetch_private_key(private_key_pem, password) {
        Ok(arc) => Ok((atoms::ok(), ResourceArc::new(arc)).encode(env)),
        Err(ref error) => Err(rustler::Error::Term(Box::new(error_to_term(error)))),
    }
}

// fetches the private key from the pem
fn do_fetch_private_key(private_key_pem: String, password: Option<String>) -> Result<MyRsaPrivateKey, Error> {
    match password {
        Some(pw) => {
            let private_key = RsaPrivateKey::from_pkcs8_encrypted_pem(&private_key_pem, &pw)?;
            Ok(MyRsaPrivateKey(private_key))
        },
        None => {
            let private_key = RsaPrivateKey::from_pkcs8_pem(&private_key_pem)?;
            Ok(MyRsaPrivateKey(private_key))
        }
    }
}

/// Decrypts the encrypted AES key encoding as base64 string using the private key reference.
///
#[rustler::nif(schedule = "DirtyCpu")]
fn decrypt_aes_key(env: Env, private_key: ResourceArc<MyRsaPrivateKey>, encrypted_aes_key: String) -> Result<Term, rustler::Error> {
    match do_decrypt_aes_key(env, private_key, encrypted_aes_key) {
        Ok(binary) => Ok((atoms::ok(), binary).encode(env)),
        Err(ref error) => Err(rustler::Error::Term(Box::new(error_to_term(error)))),
    }
}

fn do_decrypt_aes_key(env: Env, private_key: ResourceArc<MyRsaPrivateKey>, encrypted_aes_key: String) -> Result<Binary, Error> {
    let padding = Oaep::new::<Sha256>();
    let decrypted_aes_key = BASE64_STANDARD.decode(encrypted_aes_key)?;
    let aes_key = private_key.0.decrypt(padding, &decrypted_aes_key)?;
    let mut result: OwnedBinary = OwnedBinary::new(aes_key.len()).ok_or(Error::AllocErr)?;
    result.as_mut_slice().copy_from_slice(&aes_key);
    Ok(Binary::from_owned(result, env))
}

rustler::init!("Elixir.RCrypto");
