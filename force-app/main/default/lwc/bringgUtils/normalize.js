/*
 * Copyright (c) 2019, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: MIT
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/MIT
 */

export function normalizeString(value, config = {}) {
    const { fallbackValue = '', validValues, toLowerCase = true } = config;
    let normalized = (typeof value === 'string' && value.trim()) || '';
    normalized = toLowerCase ? normalized.toLowerCase() : normalized;
    if (validValues && validValues.indexOf(normalized) === -1) {
        normalized = fallbackValue;
    }
    return normalized;
}

export function normalizeBoolean(value) {
    return typeof value === 'string' || !!value;
}

export function normalizeArray(value) {
    if (Array.isArray(value)) {
        return value;
    }
    return [];
}

export function normalizeAriaAttribute(value) {
    let arias = Array.isArray(value) ? value : [value];
    arias = arias
        .map((ariaValue) => {
            if (typeof ariaValue === 'string') {
                return ariaValue.replace(/\s+/g, ' ').trim();
            }
            return '';
        })
        .filter((ariaValue) => !!ariaValue);

    return arias.length > 0 ? arias.join(' ') : null;
}

export function normalizeRecordId(recordId) {
    if (!recordId) {
        return null;
    }

    if (recordId.length === 15) {
        let suffix = '';
        const CASE_DECODE_STRING = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456';

        for (let set = 0; set < 3; ++set) {
            let decodeValue = 0;
            for (let bit = 0; bit < 5; bit++) {
                const c = recordId.charAt(set * 5 + bit);
                if (c >= 'A' && c <= 'Z') {
                    decodeValue += 1 << bit;
                }
            }

            suffix += CASE_DECODE_STRING.charAt(decodeValue);
        }

        return recordId + suffix;
    } else if (recordId.length === 18) {
        return recordId;
    }
    return null;
}

export const VARIANT = {
    STANDARD: 'standard',
    LABEL_HIDDEN: 'label-hidden',
    LABEL_STACKED: 'label-stacked',
    LABEL_INLINE: 'label-inline'
};

export function normalizeVariant(value) {
    return normalizeString(value, {
        fallbackValue: VARIANT.STANDARD,
        validValues: [
            VARIANT.STANDARD,
            VARIANT.LABEL_HIDDEN,
            VARIANT.LABEL_STACKED,
            VARIANT.LABEL_INLINE
        ]
    });
}