use wasm_bindgen::prelude::*;
use js_sys::Float64Array;

/// Compute the arithmetic mean of values.
/// Returns NaN if array is empty.
#[wasm_bindgen]
pub fn mean(values: &Float64Array) -> f64 {
    let len = values.length() as usize;
    if len == 0 {
        return f64::NAN;
    }
    let mut sum = 0.0;
    for i in 0..len {
        sum += values.get_index(i as u32);
    }
    sum / (len as f64)
}

/// Compute percent change between first and last value.
/// Returns NaN if fewer than 2 values, or if first == 0.
#[wasm_bindgen]
pub fn pct_change(values: &Float64Array) -> f64 {
    let len = values.length() as usize;
    if len < 2 {
        return f64::NAN;
    }
    let first = values.get_index(0);
    let last = values.get_index((len - 1) as u32);
    if first == 0.0 {
        return f64::NAN;
    }
    ((last - first) / first.abs()) * 100.0
}

/// Compute slope (linear trend) of values across index positions.
/// Returns NaN if fewer than 2 values.
#[wasm_bindgen]
pub fn slope(values: &Float64Array) -> f64 {
    let n = values.length() as usize;
    if n < 2 {
        return f64::NAN;
    }

    let n_f = n as f64;
    let x_mean = (n_f - 1.0) / 2.0;

    // mean of y
    let mut y_sum = 0.0;
    for i in 0..n {
        y_sum += values.get_index(i as u32);
    }
    let y_mean = y_sum / n_f;

    let mut num = 0.0;
    let mut den = 0.0;
    for i in 0..n {
        let x = i as f64;
        let dx = x - x_mean;
        let dy = values.get_index(i as u32) - y_mean;
        num += dx * dy;
        den += dx * dx;
    }

    if den == 0.0 {
        f64::NAN
    } else {
        num / den
    }
}

/// Compute Pearson correlation coefficient between two equal-length arrays.
/// Returns NaN if arrays are empty or denominator is zero.
#[wasm_bindgen]
pub fn pearson(a: &Float64Array, b: &Float64Array) -> f64 {
    let na = a.length() as usize;
    let nb = b.length() as usize;
    let n = std::cmp::min(na, nb);
    if n == 0 {
        return f64::NAN;
    }

    let n_f = n as f64;
    let mut mean_a = 0.0;
    let mut mean_b = 0.0;

    for i in 0..n {
        mean_a += a.get_index(i as u32);
        mean_b += b.get_index(i as u32);
    }
    mean_a /= n_f;
    mean_b /= n_f;

    let mut num = 0.0;
    let mut den_a = 0.0;
    let mut den_b = 0.0;

    for i in 0..n {
        let da = a.get_index(i as u32) - mean_a;
        let db = b.get_index(i as u32) - mean_b;
        num += da * db;
        den_a += da * da;
        den_b += db * db;
    }

    let denom = (den_a * den_b).sqrt();
    if denom == 0.0 {
        f64::NAN
    } else {
        num / denom
    }
}
