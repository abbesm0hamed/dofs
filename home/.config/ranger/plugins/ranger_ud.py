import os
from ranger.api.commands import Command

class ueberzug(Command):
    def execute(self):
        self.fm.notify("Enabling ueberzug")
        self.fm.settings.preview_image = True
        self.fm.settings.preview_image_method = 'ueberzug'

class disable_ueberzug(Command):
    def execute(self):
        self.fm.notify("Disabling ueberzug")
        self.fm.settings.preview_image = False

