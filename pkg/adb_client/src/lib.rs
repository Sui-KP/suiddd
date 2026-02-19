use std::ffi::CString;
use std::os::raw::c_char;
use adb_client::server::ADBServer;
#[unsafe(no_mangle)]
pub extern "C" fn list_devices() -> *mut c_char {
    let mut server = ADBServer::default();
    match server.devices() {
        Ok(devices) => {
            let serials: Vec<String> = devices.into_iter().map(|d| d.identifier).collect();
            let joined = serials.join(",");
            let c_str = CString::new(joined).unwrap_or_else(|_| CString::new("").unwrap());
            c_str.into_raw()
        },
        Err(_) => CString::new("").unwrap().into_raw(),
    }
}
#[unsafe(no_mangle)]
pub extern "C" fn free_string(s: *mut c_char) {
    if s.is_null() { return; }
    unsafe {
        let _ = CString::from_raw(s);
    }
}