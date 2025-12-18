global class UpdateUserRoleInAccountSchedular implements Schedulable {
   global void execute(SchedulableContext sc) {
      Database.executeBatch(new UpdateUserRoleInAccount());
   }
}