#![no_std]
#![feature(asm)]
#![feature(intrinsics)]
#![feature(lang_items)]
#![feature(compiler_builtins_lib)]
#![feature(custom_attribute)]
#![allow(unused_variables)]

extern crate uefi;
//extern crate alloc_uefi;
extern crate rlibc;
extern crate compiler_builtins;
extern crate projectasiago_feta as feta;
extern crate projectasiago_mish as mish;

use uefi::SimpleTextOutput;
use uefi::graphics::{PixelFormat, Pixel};
use core::num::Wrapping;
use core::mem;
use core::fmt::Write;

/// converts a char into a &str
macro_rules! char_to_str {
	($x:expr) => {{
		let v: &[u8] = &[$x as u8];
		let buff: &str = unsafe {
			&*(v as *const [u8] as *const str)
		};
	
		&buff
	}};
}

pub struct Writer {}

impl Write for Writer {
	fn write_str(&mut self, s: &str) -> core::fmt::Result {
		for c in s.chars() {
			if c == '\n' {
				uefi::get_system_table().console().write("\n\r");
			} else {
				uefi::get_system_table().console().write(char_to_str!(c));
			}
		}
		Ok(())
	}
}

#[lang = "panic_fmt"]
#[no_mangle]
fn handle_panic(_msg: core::fmt::Arguments,
                _file: &'static str,
                _line: u32) -> ! {
	let mut writer = Writer {};
	uefi::get_system_table().console().set_attribute(uefi::Attribute::new(
		uefi::ForegroundColor::Red,
		uefi::BackgroundColor::Black,
	));
	uefi::get_system_table().console().write("panic detected, info below:\n\r");
	core::fmt::write(&mut writer, _msg);
	uefi::get_system_table().console().write("\n\r");
	uefi::get_system_table().console().set_attribute(uefi::Attribute::new(
		uefi::ForegroundColor::White,
		uefi::BackgroundColor::Black,
	));
	loop {}
}

#[allow(unreachable_code)]
#[no_mangle]
pub extern "win64" fn efi_main(hdl: uefi::Handle, sys: uefi::SystemTable) -> uefi::Status {
	uefi::initialize_lib(&hdl, &sys);
	//alloc_uefi::setup_alloc(sys, bs.handle_protocol::<LoadedImageProtocol>(hdl).unwrap().image_data_type);
	
	let bs = uefi::get_system_table().boot_services();
	let rs = uefi::get_system_table().runtime_services();
	
	let gop = uefi::graphics::GraphicsOutputProtocol::new().unwrap();
	
	let mut mode: u32 = 0;
	for i in 0..gop.get_max_mode() {
		let info = gop.query_mode(i).unwrap();
		
		if info.pixel_format != PixelFormat::RedGreenBlue
			&& info.pixel_format != PixelFormat::BlueGreenRed { continue; }
		if info.horizontal_resolution > 1920 && info.vertical_resolution > 1080 { continue; }
		if info.horizontal_resolution == 1920 && info.vertical_resolution == 1080 {
			mode = i;
			break;
		}
		mode = i;
	};
	
	gop.set_mode(mode);
	
	uefi::get_system_table().console().write(mish::hello_world());
	uefi::get_system_table().console().write("\n\r");
	uefi::get_system_table().console().write("Hello, World!\n\rvendor: ");
	uefi::get_system_table().console().write_raw(uefi::get_system_table().vendor());
	uefi::get_system_table().console().write("\n\r");
	
	let tm = rs.get_time().unwrap();
//    let mut xorshift_value = Wrapping(tm.nanosecond as u64);
	let mut xorshift_value = Wrapping(14312312512314u64);
	let mut xorshift = || {
		xorshift_value ^= xorshift_value >> 12;
		xorshift_value ^= xorshift_value << 25;
		xorshift_value ^= xorshift_value >> 27;
		xorshift_value = xorshift_value * Wrapping(2685821657736338717u64);
		xorshift_value.0
	};
	
	/*let info = gop.query_mode(mode).unwrap();
	let resolutin_w : usize = info.horizontal_resolution as usize;
	let resolutin_h : usize = info.vertical_resolution as usize;
	const AREA : usize = 800 * 600;

	let bitmap = bs.allocate_pool::<Pixel>(mem::size_of::<Pixel>() * AREA).unwrap();
	loop {
		let px = Pixel::new((xorshift() % 255) as u8, (xorshift() % 255) as u8, (xorshift() % 255) as u8);
		//let mut writer = Writer {};
		//write!(writer, "red: {}, blue: {}, green: {}\n\r", px.red, px.blue, px.green).unwrap();
		let mut count = 0;
		while count < AREA {
			unsafe{*bitmap.offset(count as isize) = px.clone()};
			count += 1;
		}
		gop.draw(bitmap, resolutin_w/2-400, resolutin_h/2-300, 800, 600);
		bs.stall(100000);
	}*/
	
	let (memory_map, memory_map_size, map_key, descriptor_size, descriptor_version) = uefi::lib_memory_map();
	bs.exit_boot_services(&hdl, &map_key);
	rs.set_virtual_address_map(&memory_map_size, &descriptor_size, &descriptor_version, memory_map);
	
	loop {}
	uefi::Status::Success
}

// We can ignore this, I think. We aren't doing any unwind resumes.
// https://doc.rust-lang.org/std/panic/fn.resume_unwind.html
/*#[no_mangle]
pub extern "C" fn _Unwind_Resume() -> ! {
	loop {}
}*/

// We can also ignore this, I think. panic!() will always halt right there and not return so this shouldn't be called.
// https://stackoverflow.com/questions/329059/what-is-gxx-personality-v0-for
#[lang = "eh_personality"]
#[no_mangle]
pub extern fn rust_eh_personality() {
	uefi::get_system_table().console().write("eh_personality\n\r");
}