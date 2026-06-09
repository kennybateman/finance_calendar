class DueDate {

  static DateTime findNextDueDateAfterOrOn(DateTime targetDate, DateTime knownDueDate, String frequency, int anchorDay){
    var dueDate = knownDueDate;
    /* 
      Roll due date backward to find first _before_ target date. 
      May not run if already behind target date. 
      Might land on target date.
    */
    int limit = 360;
    while(dueDate.isAfter(targetDate)){
      if (limit <= 0) throw Exception("Over the line when going back!");
      limit--;
      dueDate = findPriorDueDate(dueDate, frequency, anchorDay);
    }
    /* 
      Roll due date forward to find first _after_ _or_ _on_ target date (not before).
      May not run if previous loop landed on target date.
    */
    limit = 360;
    while(dueDate.isBefore(targetDate)){
      if (limit <= 0) throw Exception("Over the line when going forward!");
      limit--;
      dueDate = findNextDueDate(dueDate, frequency, anchorDay);
    }
    /*
      If due date is on target date it should fall through the loops.
    */
    return dueDate;
  }

  static DateTime findNextDueDate(DateTime dueDate, String frequency, int anchorDay){
    switch(frequency){
      case "weekly":
        return DateTime(dueDate.year, dueDate.month, dueDate.day + 7);
      case "biweekly":
        return DateTime(dueDate.year, dueDate.month, dueDate.day + 14);
      case "monthly":
        return sameDayNextMonth(dueDate, anchorDay);
      default:
        throw Exception("unknown frequncy $frequency");
    }
  }

  static DateTime findPriorDueDate(DateTime dueDate, String frequency, int anchorDay){
    switch(frequency){
      case "weekly":
        return DateTime(dueDate.year, dueDate.month, dueDate.day - 7);
      case "biweekly":
        return DateTime(dueDate.year, dueDate.month, dueDate.day - 14);
      case "monthly":
        return sameDayLastMonth(dueDate, anchorDay);
      default:
        throw Exception("unknown frequncy $frequency");
    }
  }

  static DateTime sameDayLastMonth(DateTime day, int? anchorDay){
    final daysInPriorMonth = DateTime(day.year, day.month, 0).day;
    /* ex: May 31 to April 31 (needs to be April 30) */
    final attemptedDayOfMonth = anchorDay ?? day.day;
    final resolvedDayOfMonth = attemptedDayOfMonth > daysInPriorMonth ? daysInPriorMonth : attemptedDayOfMonth;
    return DateTime(day.year, day.month - 1, resolvedDayOfMonth);
  }

  static DateTime sameDayNextMonth(DateTime day, int? anchorDay){
    final daysInNextMonth = DateTime(day.year, day.month + 2, 0).day;
    /* ex: March 31 to April 31 (neds to be April 30) */
    final attemptedDayOfMonth = anchorDay ?? day.day;
    final resolvedDayOfMonth = attemptedDayOfMonth > daysInNextMonth ? daysInNextMonth : attemptedDayOfMonth;
    return DateTime(day.year, day.month + 1, resolvedDayOfMonth);
  }
}