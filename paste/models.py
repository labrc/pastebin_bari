from django.db import models
from django.utils import timezone

class Paste(models.Model):
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Nota'
        verbose_name_plural = 'Notas'
    
    def __str__(self):
        return f"Nota de {self.created_at.strftime('%d/%m/%Y %H:%M')}"
    
    @property
    def preview(self):
        lines = self.content.split('\n')
        return lines[0][:100] if lines else ''