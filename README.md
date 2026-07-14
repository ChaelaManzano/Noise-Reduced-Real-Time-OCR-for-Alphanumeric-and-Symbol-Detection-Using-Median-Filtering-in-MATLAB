# Noise-Reduced Real-Time OCR for Alphanumeric and Symbol Detection Using Median Filtering in MATLAB

A real-time Optical Character Recognition (OCR) system built in MATLAB that captures live webcam video, applies median-filter-based noise reduction, and recognizes alphanumeric text with a live confidence score. Extending an earlier static template-matching symbol recognizer into a practical, real-time tool.

This was built as a final project for **ECE 414 – Signals, Spectra, and Signal Processing** at Batangas State University.

## Overview

The project explores how **filter design**, specifically 2D median filtering, can improve OCR reliability under real-world capture conditions (noise, uneven lighting, motion). It progresses through three stages:

1. **Symbol Recognition (baseline)** — static image input, pixel-wise template matching against a small set of fixed geometric symbols (plus, minus, triangle, square, circle, etc.)
2. **Static OCR (reference)** — static image input, MATLAB's `ocr()` (Tesseract LSTM) with `imadjust`/`imsharpen`/adaptive binarization preprocessing, but no spatial noise filtering and no live input
3. **Live OCR + Median Filter (final system)** — continuous webcam capture, median-filtered preprocessing, real-time OCR with a color-coded confidence indicator and save-to-file support

## Why Median Filtering?

A median filter replaces each pixel with the median value of its neighborhood (a 3×3 kernel here). Compared to Gaussian or mean filters, it:
- **Preserves edges** — critical for OCR, since character shape/boundary sharpness directly affects recognition accuracy
- **Rejects impulse ("salt-and-pepper") noise** effectively, which is a common artifact in live webcam frames caused by lighting inconsistencies

This makes it a better fit than blur-prone smoothing filters for a pipeline where the *next* stage (OCR) depends on clean edges.

## System Pipeline

```
Webcam Capture → Grayscale Conversion → Median Filter (3x3) → Resize/Enhance → OCR (Tesseract LSTM) → Confidence Scoring → GUI Display / Save
```

1. **Webcam Acquisition** — `webcamlist()` / `webcam()` / `snapshot()` capture continuous frames; OCR is only triggered every 15 frames (`processEvery`) to keep the UI responsive.
2. **Preprocessing**
   - Grayscale conversion: `Y = 0.2989R + 0.5870G + 0.1140B`
   - Median filtering: `g(x,y) = median{f(i,j)}, (i,j) ∈ Ω` over a 3×3 neighborhood
   - Resize/enhance: standard mode uses 1.5x bilinear upscaling; high-quality mode uses 3x bicubic upscaling + CLAHE (`adapthisteq`) for contrast enhancement
3. **OCR Recognition** — MATLAB's `ocr()` function (Tesseract LSTM backend) restricted to an alphanumeric + punctuation character set to shrink the search space and reduce misreads
4. **Confidence Scoring** — mean of per-character confidence values (NaNs excluded), mapped to a three-tier color-coded indicator:

   | Range | Color | Meaning |
   |---|---|---|
   | 75–100% | Green | Reliable output |
   | 50–74% | Yellow | Partial recognition |
   | 0–49% | Red | Poor lighting / unclear text |

5. **GUI Display** — dark-themed interface (live feed, detected text panel, confidence label, Save/Reset buttons)
6. **Output** — detected text can be saved as `.txt`, or the full window can be saved as `.png`

## Key Modifications From the Reference OCR Code

| # | Modification | Original Behavior | Improvement | Impact |
|---|---|---|---|---|
| 1 | Median filter | No spatial filter | `medfilt2([3 3])` added post-grayscale | Noise suppression, improved accuracy |
| 2 | Live webcam input | Single static image | Continuous webcam loop via `snapshot()` | Real-time detection, practical use |
| 3 | Dual OCR quality mode | Fixed preprocessing path | Standard (1.5x bilinear) vs. High Quality (3x bicubic + CLAHE) | Speed/accuracy tradeoff control |
| 4 | Restricted character set | Default (broad) Tesseract charset | Alphanumeric + punctuation only | Smaller search space, better accuracy |
| 5 | Confidence indicator | None | Live color-coded mean `CharacterConfidences` | Real-time reliability feedback |
| 6 | `TextLines` output | Raw, irregular `Text` extraction | Line-by-line join via `TextLines` | Cleaner, structured output |

## Testing & Results

The system was evaluated on recorded scenarios covering printed text (various sizes), handwritten uppercase/lowercase text, numbers, symbols, mixed alphanumeric+symbol content, varying camera distance, and different lighting conditions. Sample results:

| Condition | Accuracy | Observation |
|---|---|---|
| Big printed text | 99–100% | Fast, reliable recognition |
| Small printed text | 99–100% | Still accurately detected |
| Numbers | 99% | High accuracy, rapid detection |
| Handwritten capitals | 98–100% | Clear detection |
| Handwritten lowercase | 98–100% | More sensitive to writing clarity |
| Alphanumeric + symbols (30 sec) | Alphanumeric 55% / Symbols 40% | Symbols consistently underperform letters/numbers |
| Symbols only (1–2 min) | ~25% | Weakest case — thin strokes and similar shapes confuse recognition |
<img width="1243" height="708" alt="image" src="https://github.com/user-attachments/assets/ec9a93ec-c50c-495d-8d9f-fae0e28ca96d" />
<img width="782" height="508" alt="image" src="https://github.com/user-attachments/assets/8145be9c-8708-4608-ad03-e37e7374aae7" />

**Overall:** the system performs best on printed text and numbers, is solid on clear handwriting, and is weakest on symbol-only content — consistent with OCR engines being fundamentally tuned for language characters rather than arbitrary shapes.

Full test videos are linked in Appendix A of the project report.

## Known Limitations / Future Work

- Symbol recognition (as opposed to alphanumeric text) remains unreliable — Tesseract's LSTM model is trained for language characters, not arbitrary geometric shapes.
- No adaptive binarization or bounding-box overlay on detected text yet.
- Frame throttling (`processEvery = 15`) is a fixed constant rather than dynamically adjusted based on system performance.
- Handwritten text recognition is sensitive to stroke thickness, spacing, and camera stability.

## Team

Baliat, Cazandra L. · Manzano, Char Chaela C. · Ramos, Jean Joy C.
BS Electronics Engineering — Batangas State University, Alangilan Campus
Submitted to Dr. Antonette V. Chua, ECE 414

## License

No license specified — add one (e.g., MIT) if you'd like others to be able to reuse this freely.
