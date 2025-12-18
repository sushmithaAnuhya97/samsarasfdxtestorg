/**
 * Created by vikasmishra on 2021-06-09.
 */

public with sharing class GenerateGUID {

    private static final String HEX_CHARACTERS = '0123456789abcdef';
    private static final List<String> HEX_CHARACTER_LIST = HEX_CHARACTERS.split('');
    private static final Integer HEX_BASE = HEX_CHARACTERS.length();
    /**
    * This method will generate a GUID standardized by the Open Software Foundation (OSF)
    *
    * @since    2018-12-31
    *
    * @return  String - 36 character GUID of format 8-4-4-4-12
    *
    **/
    @InvocableMethod (Label='Get GUID' Description='Returns the generated GuiID in form of List' Category='Util')
    public static List<String> generateUtil() {
        String randomStringAsHex = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        String versionHexBits = randomStringAsHex.substring(14,16); // 7th bit
        String variantHexBits = randomStringAsHex.substring(18,20); // 9th bit
        Integer versionIntBits = convertHexToInt(versionHexBits);
        Integer variantIntBits = convertHexToInt(variantHexBits);
        Integer versionShiftedIntBits = versionIntBits & 15 | 64;  // (i & 0x0f) | 0x40
        Integer variantShiftedIntBits = variantIntBits & 63 | 128; // (i & 0x3f) | 0x80
        String versionShiftedHexBits = convertIntToHex(versionShiftedIntBits); // Always begins with 4
        String variantShiftedHexBits = convertIntToHex(variantShiftedIntBits); // Always begins with one of 8,9,a,b
        String guid = randomStringAsHex.substring(0,8) + '-' + randomStringAsHex.substring(8,12) + '-' + versionShiftedHexBits + randomStringAsHex.substring(14,16) + '-' + variantShiftedHexBits + randomStringAsHex.substring(18,20) + '-' + randomStringAsHex.substring(20);
        return new List<String>{guid};
    }

    private static String convertIntToHex(Integer integerValue) {
        String hexValue = '';
        while(integerValue > 0) {
            Integer hexCharacterIndex = Math.mod(integerValue, HEX_BASE);

            hexValue     = HEX_CHARACTER_LIST[hexCharacterIndex] + hexValue;
            integerValue = integerValue / HEX_BASE;
        }
        return hexValue;
    }

    private  static Integer convertHexToInt(String hex) {
        String[] hexValue = hex.split('');
        Integer result = 0;
        for(Integer index = 0; index < hexValue.size(); index++) {
            result = (result * 16) + hex.indexOf(hexValue[index]);
        }
        return result;
    }



}