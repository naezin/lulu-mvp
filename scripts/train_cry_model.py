#!/usr/bin/env python3
"""
LULU Baby Cry Classifier - Training Script

데이터셋: Donate-a-Cry Corpus
라이선스: ODbL 1.0 (상업 사용 가능, 출처 명시 필요)
출처: https://github.com/gveres/donateacry-corpus

실행 방법:
1. Python 3.9+ 설치
2. pip install tensorflow librosa numpy matplotlib
3. 데이터셋 다운로드: git clone https://github.com/gveres/donateacry-corpus.git
4. python train_cry_model.py

출력:
- assets/models/cry_classifier.tflite
"""

import os
import numpy as np
import librosa
import tensorflow as tf
from tensorflow import keras
from sklearn.model_selection import train_test_split
from pathlib import Path
import random

# ==========================================
# 설정
# ==========================================

# 경로 설정
DATASET_PATH = "./donateacry-corpus/donateacry_corpus_cleaned_and_updated_data"
OUTPUT_MODEL_PATH = "../assets/models/cry_classifier.tflite"

# 오디오 설정
SAMPLE_RATE = 16000  # 16kHz
DURATION = 3.0  # 3초
N_MELS = 128  # Mel 필터 개수
HOP_LENGTH = 512
N_FFT = 2048

# 모델 설정
INPUT_SHAPE = (128, 128, 1)
NUM_CLASSES = 6
BATCH_SIZE = 32
EPOCHS = 50

# 클래스 매핑 (폴더명 → 인덱스)
FOLDER_CLASS_MAP = {
    "hungry": 0,       # hu
    "tired": 1,        # ti
    "discomfort": 2,   # dc
    "belly_pain": 3,   # bp (gas)
    "burping": 4,      # bu
}
# 5: unknown (훈련 데이터 없음)

# 파일명 코드 매핑 (fallback)
CLASS_MAP = {
    "hu": 0,  # hungry
    "ti": 1,  # tired
    "dc": 2,  # discomfort
    "bp": 3,  # belly_pain (gas)
    "bu": 4,  # burping
}

# 데이터 증강 설정
AUGMENT = True
AUGMENT_FACTOR = 3  # 원본 대비 증강 배수


# ==========================================
# 유틸리티 함수
# ==========================================

def load_audio(file_path):
    """오디오 파일 로드 (3초로 패딩/트림)"""
    try:
        y, sr = librosa.load(file_path, sr=SAMPLE_RATE, duration=DURATION)

        # 목표 길이
        target_length = int(SAMPLE_RATE * DURATION)

        # 패딩 또는 트림
        if len(y) < target_length:
            y = np.pad(y, (0, target_length - len(y)))
        else:
            y = y[:target_length]

        return y
    except Exception as e:
        print(f"오디오 로드 실패: {file_path}, 에러: {e}")
        return None


def audio_to_mel_spectrogram(y):
    """오디오 → Mel Spectrogram 변환"""
    mel_spec = librosa.feature.melspectrogram(
        y=y,
        sr=SAMPLE_RATE,
        n_mels=N_MELS,
        hop_length=HOP_LENGTH,
        n_fft=N_FFT
    )

    # Log scale
    mel_spec_db = librosa.power_to_db(mel_spec, ref=np.max)

    # 정규화 (-80 ~ 0 dB → 0 ~ 1)
    mel_spec_norm = (mel_spec_db + 80) / 80
    mel_spec_norm = np.clip(mel_spec_norm, 0, 1)

    # 128x128로 리사이즈
    if mel_spec_norm.shape[1] != 128:
        mel_spec_norm = np.resize(mel_spec_norm, (128, 128))

    return mel_spec_norm


def augment_audio(y):
    """데이터 증강"""
    augmented = []

    # 1. Pitch shift (±2 semitones)
    pitch_shifts = [-2, -1, 1, 2]
    for shift in random.sample(pitch_shifts, 1):
        try:
            y_shifted = librosa.effects.pitch_shift(y, sr=SAMPLE_RATE, n_steps=shift)
            augmented.append(y_shifted)
        except:
            pass

    # 2. Time stretch (0.9x ~ 1.1x)
    stretch_rates = [0.9, 0.95, 1.05, 1.1]
    for rate in random.sample(stretch_rates, 1):
        try:
            y_stretched = librosa.effects.time_stretch(y, rate=rate)
            # 길이 맞추기
            target_length = int(SAMPLE_RATE * DURATION)
            if len(y_stretched) < target_length:
                y_stretched = np.pad(y_stretched, (0, target_length - len(y_stretched)))
            else:
                y_stretched = y_stretched[:target_length]
            augmented.append(y_stretched)
        except:
            pass

    # 3. Add noise (SNR 20~40dB)
    snr_db = random.uniform(20, 40)
    noise = np.random.randn(len(y))
    signal_power = np.mean(y ** 2)
    noise_power = signal_power / (10 ** (snr_db / 10))
    noise = noise * np.sqrt(noise_power)
    y_noisy = y + noise
    augmented.append(y_noisy)

    return augmented


# ==========================================
# 데이터 로딩
# ==========================================

def load_dataset():
    """데이터셋 로드 (폴더 기반)"""
    print("데이터셋 로드 중...")

    X = []
    y = []

    if not os.path.exists(DATASET_PATH):
        print(f"데이터셋 경로가 없습니다: {DATASET_PATH}")
        print("git clone https://github.com/gveres/donateacry-corpus.git")
        return None, None

    # 폴더별 탐색 (hungry, tired, discomfort, belly_pain, burping)
    for folder_name, class_idx in FOLDER_CLASS_MAP.items():
        folder_path = os.path.join(DATASET_PATH, folder_name)

        if not os.path.exists(folder_path):
            print(f"폴더 없음: {folder_path}")
            continue

        wav_files = [f for f in os.listdir(folder_path) if f.endswith(".wav")]
        print(f"  {folder_name}: {len(wav_files)}개 파일")

        for file in wav_files:
            file_path = os.path.join(folder_path, file)
            audio = load_audio(file_path)

            if audio is None:
                continue

            # 원본 추가
            mel_spec = audio_to_mel_spectrogram(audio)
            X.append(mel_spec)
            y.append(class_idx)

            # 증강
            if AUGMENT:
                augmented_audios = augment_audio(audio)
                for aug_audio in augmented_audios:
                    mel_spec = audio_to_mel_spectrogram(aug_audio)
                    X.append(mel_spec)
                    y.append(class_idx)

    if len(X) == 0:
        print("로드된 데이터가 없습니다!")
        return None, None

    X = np.array(X)
    y = np.array(y)

    # 채널 차원 추가
    X = X[..., np.newaxis]

    print(f"로드 완료: {len(X)} 샘플, {len(set(y))} 클래스")

    # 클래스 분포
    for folder_name, idx in FOLDER_CLASS_MAP.items():
        count = np.sum(y == idx)
        print(f"  {folder_name}: {count}개")

    return X, y


# ==========================================
# 모델 정의
# ==========================================

def create_model():
    """CNN 모델 생성"""
    model = keras.Sequential([
        # Conv Block 1
        keras.layers.Conv2D(32, (3, 3), activation='relu', padding='same',
                           input_shape=INPUT_SHAPE),
        keras.layers.BatchNormalization(),
        keras.layers.MaxPooling2D((2, 2)),
        keras.layers.Dropout(0.25),

        # Conv Block 2
        keras.layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
        keras.layers.BatchNormalization(),
        keras.layers.MaxPooling2D((2, 2)),
        keras.layers.Dropout(0.25),

        # Conv Block 3
        keras.layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
        keras.layers.BatchNormalization(),
        keras.layers.MaxPooling2D((2, 2)),
        keras.layers.Dropout(0.25),

        # Conv Block 4
        keras.layers.Conv2D(256, (3, 3), activation='relu', padding='same'),
        keras.layers.BatchNormalization(),
        keras.layers.GlobalAveragePooling2D(),

        # Dense
        keras.layers.Dense(128, activation='relu'),
        keras.layers.Dropout(0.5),
        keras.layers.Dense(NUM_CLASSES, activation='softmax'),
    ])

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.001),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )

    return model


# ==========================================
# 학습
# ==========================================

def train_model(X, y):
    """모델 학습"""
    print("\n모델 학습 시작...")

    # Train/Val 분리
    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    print(f"훈련: {len(X_train)}개, 검증: {len(X_val)}개")

    # 모델 생성
    model = create_model()
    model.summary()

    # 콜백
    callbacks = [
        keras.callbacks.EarlyStopping(
            patience=10, restore_best_weights=True
        ),
        keras.callbacks.ReduceLROnPlateau(
            factor=0.5, patience=5, min_lr=1e-6
        ),
    ]

    # 학습
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        callbacks=callbacks,
        verbose=1
    )

    # 평가
    val_loss, val_acc = model.evaluate(X_val, y_val)
    print(f"\n최종 검증 정확도: {val_acc * 100:.1f}%")

    return model


# ==========================================
# TFLite 변환
# ==========================================

def convert_to_tflite(model):
    """TFLite 변환 및 저장"""
    print("\nTFLite 변환 중...")

    # Keras 모델 저장 후 변환 (호환성 향상)
    import tempfile
    with tempfile.TemporaryDirectory() as tmpdir:
        saved_model_path = os.path.join(tmpdir, "saved_model")
        model.export(saved_model_path)

        # 변환
        converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_path)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS
        ]
        converter._experimental_lower_tensor_list_ops = False
        tflite_model = converter.convert()

    # 저장
    output_path = Path(OUTPUT_MODEL_PATH)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, 'wb') as f:
        f.write(tflite_model)

    # 크기 확인
    size_mb = len(tflite_model) / (1024 * 1024)
    print(f"모델 저장됨: {output_path}")
    print(f"모델 크기: {size_mb:.2f} MB")

    return output_path


# ==========================================
# 메인
# ==========================================

def main():
    print("=" * 50)
    print("LULU Baby Cry Classifier - Training")
    print("=" * 50)

    # 데이터 로드
    X, y = load_dataset()

    if X is None:
        print("\n데이터셋을 먼저 다운로드하세요:")
        print("  cd scripts")
        print("  git clone https://github.com/gveres/donateacry-corpus.git")
        return

    # 모델 학습
    model = train_model(X, y)

    # TFLite 변환
    output_path = convert_to_tflite(model)

    print("\n" + "=" * 50)
    print("학습 완료!")
    print(f"모델 경로: {output_path}")
    print("=" * 50)
    print("\n다음 단계:")
    print("1. 모델 파일을 Flutter 프로젝트로 복사")
    print("2. 앱 다시 빌드")
    print("3. 실제 아기 울음으로 테스트")


if __name__ == "__main__":
    main()
