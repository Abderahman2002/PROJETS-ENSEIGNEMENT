from django.contrib import admin

from . import models

admin.site.register(models.SchoolClass)
admin.site.register(models.Student)
admin.site.register(models.Skill)
admin.site.register(models.SkillEvaluation)
admin.site.register(models.AttendanceRecord)
admin.site.register(models.TimetableSlot)
admin.site.register(models.Lesson)
admin.site.register(models.StudentGrade)
admin.site.register(models.BagDocument)
admin.site.register(models.CalendarEvent)
admin.site.register(models.MonthlyParentReport)
admin.site.register(models.AppNotification)
admin.site.register(models.Subscription)
admin.site.register(models.Conversation)
admin.site.register(models.Message)
