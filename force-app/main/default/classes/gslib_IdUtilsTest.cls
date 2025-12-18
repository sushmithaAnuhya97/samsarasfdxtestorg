/**
 * Copyright (c), Groundswell Cloud Solutions - https://www.gscloudsolutions.com/
 * All rights reserved.
 */

@IsTest
public class gslib_IdUtilsTest {

    @IsTest
    static void createUUID_ShouldCreateUniqueUUID() {
        // Arrange.
        Pattern expectedPattern = Pattern.compile('[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}');

        // Act.
        String id1 = gslib_IdUtils.createUUID();
        String id2 = gslib_IdUtils.createUUID();
        String id3 = gslib_IdUtils.createUUID();

        // Assert.
        System.assertNotEquals(null, id1);
        System.assertNotEquals(null, id2);
        System.assertNotEquals(null, id3);

        System.assertEquals(true, expectedPattern.matcher(id1).matches());
        System.assertEquals(true, expectedPattern.matcher(id2).matches());
        System.assertEquals(true, expectedPattern.matcher(id3).matches());

        System.assertNotEquals(id1, id2);
        System.assertNotEquals(id1, id3);
        System.assertNotEquals(id2, id3);
    }
}