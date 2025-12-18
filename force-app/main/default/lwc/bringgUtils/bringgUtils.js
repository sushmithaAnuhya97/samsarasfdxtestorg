export { deepCopy, arraysEqual, ArraySlice } from './utility';
export {
	normalizeBoolean,
	normalizeString,
	normalizeArray,
	normalizeAriaAttribute,
	normalizeRecordId,
	normalizeVariant,
	VARIANT
} from './normalize';
export {
	parseToFormattedLinkifiedParts,
	parseToFormattedParts
} from './linkify';
// export { guid } from './guid';
// export { parseError } from './sfUtils';
export {  DefaultCountries } from './countryUtils';

export {
		FieldTypes,
		Fields,
		LocalizedFieldTypes,
		DensityValues,
		LabelAlignValues,
		DensityLabelAlignMapping,
		UNSUPPORTED_REFERENCE_FIELDS } from './constants';

export function applyFieldChanges(record, changeDetails) {
	if (changeDetails != null) {
		let fieldName = changeDetails.fieldName;
		let fieldValue = changeDetails.fieldValue;
		let recordKey = changeDetails.recordKey;
		let rec;
		if (recordKey != null && recordKey !== '.') { // remove . where xxx.yyy.zzz will be implemented
			// TODO: support XXX.YYY.ZZZ too
			// "xxx.yyy.zzz".split('.').forEach(k => {if(k)console.log('log:', k)});
			// ".".split('.').forEach(k => {if(k)console.log('log:', k)});
			rec = record[recordKey];
		} else {
			rec = record;
		}
		rec[fieldName] = fieldValue;
	}
}

export function setFirstValueFromPicklist(value, picklistValues) {
	let inArray = false;
	if (value && picklistValues) {
		inArray = picklistValues.some(function (pickVal) {
			return pickVal.value == value;
		});
	}
	if (!value || !inArray) {
		if (picklistValues && picklistValues[0]) {
			return picklistValues[0].value;
		}
	}
	return value;
}